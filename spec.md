# GET /api/benchmarks
```json
{
    "operations": [
        {
            "name": "<name>",
            "complexity": "Described in big O notation",
            "scenarios": [
                "<operation_name1>",
                "<operation_name2>",
                "<operation_name3>",
            ]
        }
    ],
    "meta": {
        "timestamp": "time_in_iso8601",
        "runtime": "php-fpm|octane|swift",
    },
}
```

# GET /api/benchmarks/run/{operation}
Operation should be an operation from the /api/benchmarks result or can be "all"
It should also accept a "scenario" query parameter to further filter down which benchmark should be ran
```json
{
    "meta": {...},
    "benchmarks": {
        "<operation_name>": {
            "<scenario_name>": {...} 
        }
    }
}
```

# GET /api/health
A basic API which should return something, with a 200 status code. All other status will be seen as "unavailable"

# The runner


The benchmarkrunner should return the follwoing data after a test has been completed
```json
{
  "operation": "<name>",
  // All numbers can be floats
  "order_count": 0,
  "iterations": 0,
  "avg_time_ms": 0,
  "min_time_ms": 0,
  "max_time_ms": 0,
  "std_dev_ms": 0,
  "p50_time_ms": 0,
  "p95_time_ms": 0,
  "p99_time_ms": 0,
  "memory_used_mb": 0,
  "avg_time_per_order_ms": 0,
  "total_time_ms": 0,
}
```
