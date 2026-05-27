import http from 'k6/http';
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.1.0/index.js';
import { check } from 'k6';

const runtimePort: Record<string, number> = {
  "swift": 8080,
  "swift-reerjson": 8082,
  "php": 8000,
  "octane": 8001,
}

const rpsPeak = {
  dto_mapping: {
    product_settings: {
      "swift": 21,
      "swift-reerjson": 55,
      "php": 24,
      "octane": 25,
    },
    order_settings: {
      "swift": 20,
      "swift-reerjson": 55,
      "php": 28,
      "octane": 32,
    },
    order_products: {
      "swift": 18,
      "swift-reerjson": 60,
      "php": 33,
      "octane": 38,
    },
    full_order: {
      "swift": 10,
      "swift-reerjson": 27,
      "php": 31,
      "octane": 31,
    },
  },
  json_transformation: {
    json: {
      "swift": 500,
      "swift-reerjson": 733,
      "php": 415,
      "octane": 827,
    }
  },
  cart_calculation: {
    small_cart: {
      "swift": 15700,
      "swift-reerjson": 13000, //TODO: Validate
      "php": 500,
      "octane": 2100,
    },
    medium_cart: {
      "swift": 10700,
      "swift-reerjson": 6300,
      "php": 540,
      "octane": 2000,
    },
    large_cart: {
      "swift": 3150,
      "swift-reerjson": 1370,
      "php": 480,
      "octane": 1800,
    },
    xl_cart: {
      "swift": 750,
      "swift-reerjson": 325,
      "php": 373,
      "octane": 775,
    },
  },
  vat_calculation: {
    small_cart: {
      "swift": 20000,
      "swift-reerjson": 20000, // TODO: Validate
      "php": 530,
      "octane": 2050,
    },
    medium_cart: {
      "swift": 16000,
      "swift-reerjson": 20000, // TODO: Validate
      "php": 540,
      "octane": 2120,
    },
    large_cart: {
      "swift": 14500,
      "swift-reerjson": 20300, // TODO: Validate
      "php": 435,
      "octane": 1950,
    },
    xl_cart: {
      "swift": 18400,
      "swift-reerjson": 18800,
      "php": 400,
      "octane": 882,
    },
  },
  excel_generation: {
    excel: {
      "swift": 25, // FIXME: Can be 26
      "swift-reerjson": 39,
      "php": 2, // TODO: Can potentially handle 3
      "octane": 2, // TODO: Validate, can be 1, can be 3
    }
  },
  pdf_generation: {
    single: {
      "swift": 23,
      "swift-reerjson": 32,
      "php": 17,
      "octane": 17,
    },
    zip: {
      "swift": 2,
      "swift-reerjson": 2,
      "php": 1,
      "octane": 1, // Will potential die under this
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
      preAllocatedVUs: 5000,
      stages: [
        { duration: '1m', target: 1 }, // Scaling up
        { duration: '15m', target: 1 }, // Hold peakk
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
  http.post(`http://127.0.0.1:${runtimePort[__ENV.RUNTIME ?? "swift"]}/api/benchmarks/preload`);
}

export default function() {
  let res = http.get(`http://127.0.0.1:${runtimePort[__ENV.RUNTIME ?? "swift"]}/api/benchmarks/single/${__ENV.OPERATION}/${__ENV.SCENARIO}`, { timeout: 120_000, tags: { runtime: __ENV.RUNTIME ?? "swift" } });
  check(res, { "status is in 2xx range": (res) => res.status >= 200 && res.status <= 300 });
}

export function handleSummary(data) {
  return {
    'stdout': textSummary(data, { indent: ' ', enableColors: true }), // Show the text summary to stdout...
    [`results/${__ENV.RUNTIME ?? "swift"}-${__ENV.OPERATION}-${__ENV.SCENARIO}-stress.json`]: JSON.stringify(data), // and a JSON with all the details...
  };
}
