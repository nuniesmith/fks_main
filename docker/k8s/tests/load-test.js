import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const healthCheckDuration = new Trend('health_check_duration');

// Test configuration
export const options = {
  stages: [
    { duration: '30s', target: 10 },   // Ramp up to 10 users
    { duration: '1m', target: 50 },    // Ramp up to 50 users
    { duration: '2m', target: 50 },    // Stay at 50 users for 2 minutes
    { duration: '30s', target: 100 },  // Spike to 100 users
    { duration: '1m', target: 100 },   // Hold at 100 users
    { duration: '30s', target: 0 },    // Ramp down to 0
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],     // 95% of requests under 500ms
    http_req_failed: ['rate<0.01'],       // Less than 1% failures
    errors: ['rate<0.1'],                 // Less than 10% errors
    health_check_duration: ['p(99)<1000'], // 99% health checks under 1s
  },
};

// Base URL for the service
const BASE_URL = 'http://localhost:8000';

export default function () {
  // Test 1: Health endpoint
  const healthRes = http.get(`${BASE_URL}/health/`);
  const healthCheck = check(healthRes, {
    'health status is 200': (r) => r.status === 200,
    'health response time < 500ms': (r) => r.timings.duration < 500,
    'health response is JSON': (r) => r.headers['Content-Type'] && r.headers['Content-Type'].includes('application/json'),
  });
  
  healthCheckDuration.add(healthRes.timings.duration);
  errorRate.add(!healthCheck);

  // Test 2: Home page
  const homeRes = http.get(`${BASE_URL}/`);
  const homeCheck = check(homeRes, {
    'home status is 200': (r) => r.status === 200,
    'home response time < 1000ms': (r) => r.timings.duration < 1000,
    'home page has content': (r) => r.body.includes('FKS'),
  });
  
  errorRate.add(!homeCheck);

  // Test 3: Admin page (should redirect or show login)
  const adminRes = http.get(`${BASE_URL}/admin/`);
  const adminCheck = check(adminRes, {
    'admin status is 200 or 302': (r) => r.status === 200 || r.status === 302,
    'admin response time < 500ms': (r) => r.timings.duration < 500,
  });
  
  errorRate.add(!adminCheck);

  // Random sleep between 1-3 seconds to simulate real user behavior
  sleep(Math.random() * 2 + 1);
}

export function handleSummary(data) {
  return {
    'k8s/tests/load-test-summary.json': JSON.stringify(data, null, 2),
    stdout: textSummary(data, { indent: ' ', enableColors: true }),
  };
}

function textSummary(data, options) {
  const indent = options.indent || '';
  const enableColors = options.enableColors || false;
  
  let summary = `\n${indent}Performance Test Summary\n`;
  summary += `${indent}========================\n\n`;
  
  const metrics = data.metrics;
  
  summary += `${indent}HTTP Request Metrics:\n`;
  summary += `${indent}  - Total Requests: ${metrics.http_reqs.values.count}\n`;
  summary += `${indent}  - Request Rate: ${metrics.http_reqs.values.rate.toFixed(2)} req/s\n`;
  summary += `${indent}  - Failed Requests: ${(metrics.http_req_failed.values.rate * 100).toFixed(2)}%\n`;
  summary += `${indent}  - Duration p95: ${metrics.http_req_duration.values['p(95)'].toFixed(2)}ms\n`;
  summary += `${indent}  - Duration p99: ${metrics.http_req_duration.values['p(99)'].toFixed(2)}ms\n`;
  summary += `${indent}  - Duration avg: ${metrics.http_req_duration.values.avg.toFixed(2)}ms\n\n`;
  
  summary += `${indent}Custom Metrics:\n`;
  summary += `${indent}  - Error Rate: ${(metrics.errors.values.rate * 100).toFixed(2)}%\n`;
  summary += `${indent}  - Health Check p99: ${metrics.health_check_duration.values['p(99)'].toFixed(2)}ms\n\n`;
  
  summary += `${indent}Thresholds:\n`;
  const thresholds = data.root_group.checks;
  for (const check of thresholds || []) {
    const status = check.passes === check.fails + check.passes ? '✓' : '✗';
    summary += `${indent}  ${status} ${check.name}: ${check.passes}/${check.passes + check.fails} passed\n`;
  }
  
  return summary;
}
