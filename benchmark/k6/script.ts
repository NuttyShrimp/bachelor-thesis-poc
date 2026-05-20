import http from 'k6/http';
import { check } from 'k6';

// omitted from package.json but interesting: 

const runtimePort: Record<string, number> = {
  "swift": 8080,
  "php": 8000,
  "octane": 8001,
}

export const options = {
  scenarios: {
    openModel: {
      executor: 'ramping-arrival-rate',
      // executor: 'ramping-vus',
      startRate: 1,
      timeUnit: '1s',
      preAllocatedVUs: 20000,
      stages: [
        { duration: '2m', target: 2 << 3 }, // 16
        { duration: '3m', target: 2 << 4 }, // 32
        { duration: '4m', target: 2 << 5 }, // 64
        { duration: '5m', target: 2 << 6 }, // 128
        { duration: '6m', target: 2 << 7 }, // 256
        { duration: '7m', target: 2 << 8 }, // 512
        { duration: '8m', target: 2 << 9 }, // 1024
        { duration: '9m', target: 2 << 10 }, // 2046
        { duration: '10m', target: 2 << 11 }, // 4096
        { duration: '10m', target: 2 << 12 }, // 8192
        { duration: '10m', target: 2 << 13 }, // 16394
        { duration: '10m', target: 2 << 14 }, // 32788
        { duration: '10m', target: 2 << 15 }, // 65536
        { duration: '10m', target: 2 << 16 }, // 131072
      ],
    }
  },

  thresholds: {
    http_req_duration: [
      {
        threshold: 'p(95)<500',
        // abortOnFail: true,
      }
    ],
    http_req_failed: [
      {
        threshold: 'rate<=0.01',
        abortOnFail: true,
      }
    ],
    checks: [
      {
        threshold: 'rate>=0.99',
        abortOnFail: true,
      }
    ],
  },
};


// Warm the load cache/"DB"
export function setup() {
  http.post(`http://127.0.0.1:${runtimePort[__ENV.RUNTIME ?? "swift"]}/api/benchmarks/preload`);
}

export default function() {
  let res = http.get(`http://127.0.0.1:${runtimePort[__ENV.RUNTIME ?? "swift"]}/api/benchmarks/single/${__ENV.OPERATION}/${__ENV.SCENARIO}`, { timeout: 300_000 });
  check(res, { "status is in 2xx range": (res) => res.status >= 200 && res.status <= 300 });
  // sleep(1);
}
