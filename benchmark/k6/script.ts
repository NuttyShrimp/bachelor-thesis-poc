import http from 'k6/http';
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.1.0/index.js';
import { check } from 'k6';

// omitted from package.json but interesting: 

const runtimePort: Record<string, number> = {
  "swift": 8080,
  "swift-reerjson": 8082,
  "php": 8000,
  "octane": 8001,
}

export const options = {
  setupTimeout: 180000,
  scenarios: {
    openModel: {
      executor: 'ramping-arrival-rate',
      // executor: 'ramping-vus',
      startRate: 1,
      timeUnit: '1s',
      preAllocatedVUs: 5000,
      stages: [
        { duration: '2m', target: 2 << 3 }, // 16
        { duration: '2m', target: 2 << 4 }, // 32
        { duration: '2m', target: 2 << 5 }, // 64
        { duration: '3m', target: 2 << 6 }, // 128
        { duration: '4m', target: 2 << 7 }, // 256
        { duration: '5m', target: 2 << 8 }, // 512
        { duration: '6m', target: 2 << 9 }, // 1024
        { duration: '2m', target: 2 << 10 }, // 2046 + reset tim scaling to speed-up tests
        { duration: '3m', target: 2 << 11 }, // 4096
        { duration: '4m', target: 2 << 12 }, // 8192
        { duration: '10m', target: 2 << 13 }, // 16394 + jump to ten because experience learns in this stage alot of tests drop off
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
    dropped_iterations: [
      {
        threshold: 'count < 250',
        abortOnFail: true,
      }
    ],
  },
  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(90)', 'p(95)', 'p(99)', 'p(99.99)', 'count'],
};


// Warm the load cache/"DB"
export function setup() {
  http.post(`http://127.0.0.1:${runtimePort[__ENV.RUNTIME ?? "swift"]}/api/benchmarks/preload`);
}

export default function() {
  let res = http.get(`http://127.0.0.1:${runtimePort[__ENV.RUNTIME ?? "swift"]}/api/benchmarks/single/${__ENV.OPERATION}/${__ENV.SCENARIO}`, { timeout: 120_000, tags: { runtime: __ENV.RUNTIME ?? "swift" } });
  check(res, { "status is in 2xx range": (res) => res.status >= 200 && res.status <= 300 });
  // sleep(1);
}

export function handleSummary(data) {
  return {
    'stdout': textSummary(data, { indent: ' ', enableColors: true }), // Show the text summary to stdout...
    [`results/${__ENV.RUNTIME ?? "swift"}-${__ENV.OPERATION}-${__ENV.SCENARIO}.json`]: JSON.stringify(data), // and a JSON with all the details...
  };
}
