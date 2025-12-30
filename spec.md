A runner should be implemented which can run benchmarks that return the following pieces of data:
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

An endpoint which will perform a benchmark, regardless if it is a specific scenario/category/... will always return the following structure:
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
