import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '1m', target: 10 },   // Ramp up to 10 users over 1 min
    { duration: '2m', target: 10 },   // Stay at 10 users for 2 min
    { duration: '30s', target: 0 },   // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<1000'],  // 95% under 1s (relaxed)
    http_req_failed: ['rate<0.05'],     // Less than 5% failures
  },
};

export default function() {
  const res = http.get('http://localhost:8000/health/');
  
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time OK': (r) => r.timings.duration < 1000,
  });
  
  sleep(2);  // 0.5 requests/sec per user = 5 req/sec total at peak
}
