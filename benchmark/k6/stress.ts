import http from 'k6/http';
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.1.0/index.js';
import { check } from 'k6';

const runtimePort: Record<string, number> = {
  "swift": 8080,
  "swift-reerjson": 8082,
  "swift-yyjson": 8083,
  "php": 8000,
  "octane": 8001,
}

const rpsPeak = {
  dto_mapping: {
    product_settings: {
      "swift": 18,
      "swift-reerjson": 30,
      "swift-yyjson": 40,
      "php": 24,
      "octane": 210,
    },
    order_settings: {
      "swift": 16,
      "swift-reerjson": 30,
      "swift-yyjson": 35,
      "php": 28,
      "octane": 140,
    },
    order_products: {
      "swift": 15,
      "swift-reerjson": 33,
      "swift-yyjson": 40,
      "php": 33,
      "octane": 170,
    },
    full_order: {
      "swift": 7,
      "swift-reerjson": 15,
      "swift-yyjson": 18,
      "php": 31,
      "octane": 90,
    },
  },
  json_transformation: {
    json: {
      "swift": 500,
      "swift-reerjson": 600,
      "swift-yyjson": 950,
      "php": 400,
      "octane": 1000,
    }
  },
  cart_calculation: {
    small_cart: {
      "swift": 15000,
      "swift-reerjson": 11500,
      "swift-yyjson": 21000,
      "php": 370,
      "octane": 2000,
    },
    medium_cart: {
      "swift": 10000,
      "swift-reerjson": 5000,
      "swift-yyjson": 18500,
      "php": 350,
      "octane": 2000,
    },
    large_cart: {
      "swift": 3000,
      "swift-reerjson": 1200,
      "swift-yyjson": 11500,
      "php": 300,
      "octane": 1800,
    },
    xl_cart: {
      "swift": 750,
      "swift-reerjson": 310,
      "swift-yyjson": 5300,
      "php": 360,
      "octane": 1150,
    },
  },
  vat_calculation: {
    small_cart: {
      "swift": 19500,
      "swift-reerjson": 19000,
      "swift-yyjson": 21000,
      "php": 500,
      "octane": 2000,
    },
    medium_cart: {
      "swift": 16000,
      "swift-reerjson": 18500,
      "swift-yyjson": 19500,
      "php": 500,
      "octane": 2050,
    },
    large_cart: {
      "swift": 14500,
      "swift-reerjson": 19000,
      "swift-yyjson": 19000,
      "php": 435,
      "octane": 1850,
    },
    xl_cart: {
      "swift": 14000,
      "swift-reerjson": 17000,
      "swift-yyjson": 18000,
      "php": 400,
      "octane": 1900,
    },
  },
  excel_generation: {
    excel: {
      "swift": 25,
      "swift-reerjson": 28,
      "swift-yyjson": 60,
      "php": 1,
      "octane": 2,
    }
  },
  pdf_generation: {
    single: {
      "swift": 18,
      "swift-reerjson": 19,
      "swift-yyjson": 25,
      "php": 10,
      "octane": 17,
    },
    zip: {
      "swift": 2,
      "swift-reerjson": 1,
      "swift-yyjson": 1,
      "php": 1,
      "octane": 1,
    },
  }
}

export const options = {
  setupTimeout: 180000,
  scenarios: {
    openModel: {
      executor: 'ramping-arrival-rate',
      // executor: 'ramping-vus',
      startRate: 1,
      timeUnit: '1s',
      preAllocatedVUs: 10000,
      stages: [
        { duration: '1m', target: 1 }, // Scaling up
        { duration: '10m', target: 1 }, // Hold peakk
        { duration: '1m', target: 0 }, // Scaling down
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

if (!__ENV.SCENARIO || !__ENV.OPERATION) {
  throw ReferenceError("Missing SCENARIO or OPERATION env variable")
}

options.scenarios.openModel.stages[0].target = rpsPeak[__ENV.OPERATION][__ENV.SCENARIO][__ENV.RUNTIME]
options.scenarios.openModel.stages[1].target = rpsPeak[__ENV.OPERATION][__ENV.SCENARIO][__ENV.RUNTIME]

// Warm the load cache/"DB"
export function setup() {
  http.post(`http://${__ENV.HOST ?? "localhost"}:${runtimePort[__ENV.RUNTIME ?? "swift"]}/api/benchmarks/preload`);
}

export default function() {
  let res = http.get(`http://${__ENV.HOST ?? "localhost"}:${runtimePort[__ENV.RUNTIME ?? "swift"]}/api/benchmarks/single/${__ENV.OPERATION}/${__ENV.SCENARIO}`, { timeout: 120_000, tags: { runtime: __ENV.RUNTIME ?? "swift" } });
  check(res, { "status is in 2xx range": (res) => res.status >= 200 && res.status <= 300 });
}

export function handleSummary(data) {
  return {
    'stdout': textSummary(data, { indent: ' ', enableColors: true }), // Show the text summary to stdout...
    [`results/${__ENV.RUNTIME ?? "swift"}-${__ENV.OPERATION}-${__ENV.SCENARIO}-stress.json`]: JSON.stringify(data), // and a JSON with all the details...
  };
}
