import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const healthCheckDuration = new Trend('health_check_duration');

export const options = {
  stages: [
    { duration: '1m', target: 10 },   // Ramp to 10 users
    { duration: '2m', target: 25 },   // Ramp to 25 users
    { duration: '2m', target: 25 },   // Hold at 25 users
    { duration: '1m', target: 50 },   // Spike to 50 users
    { duration: '1m', target: 0 },    // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<1000'],     // 95% under 1s
    http_req_failed: ['rate<0.05'],        // Less than 5% failures
    errors: ['rate<0.1'],                  // Less than 10% errors
  },
};

// Using Ingress URLs (stable, no port-forward)
const BASE_URL = 'http://fks-trading.local';
const EXECUTION_URL = 'http://execution.fks-trading.local';

export default function () {
  // Test 1: Main UI health
  const healthRes = http.get(`${BASE_URL}/health/`);
  const healthCheck = check(healthRes, {
    'health status is 200': (r) => r.status === 200,
    'health response time < 1s': (r) => r.timings.duration < 1000,
  });
  
  healthCheckDuration.add(healthRes.timings.duration);
  errorRate.add(!healthCheck);

  // Test 2: Home page
  const homeRes = http.get(`${BASE_URL}/`);
  check(homeRes, {
    'home status is 200': (r) => r.status === 200,
    'home response time < 2s': (r) => r.timings.duration < 2000,
  });

  // Test 3: Execution service
  const execRes = http.get(`${EXECUTION_URL}/health`);
  check(execRes, {
    'execution status is 200': (r) => r.status === 200,
    'execution healthy': (r) => r.body.includes('healthy'),
  });

  sleep(1);
}
