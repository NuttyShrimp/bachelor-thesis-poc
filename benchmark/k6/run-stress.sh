#!/usr/bin/env bash

# sudo sysctl -w net.ipv4.ip_local_port_range="1024 65535"
# sudo sysctl -w net.ipv4.tcp_tw_reuse=1
# sudo sysctl -w net.ipv4.tcp_timestamps=1
# ulimit -n 250000

declare -A operations=(
  ["dto_mapping"]="product_settings order_settings order_products full_order"
  ["json_transformation"]="json"
  ["cart_calculation"]="small_cart medium_cart large_cart xl_cart"
  ["vat_calculation"]="small_cart medium_cart large_cart xl_cart"
  # ["excel_generation"]="excel"
  ["pdf_generation"]="single zip"
)

for key in "${!operations[@]}"; do
  echo "Key: $key"
  echo "Values: ${operations[$key]}"
  # Split the values into an array
  IFS=' ' read -ra values <<< "${operations[$key]}"
  for value in "${values[@]}"; do
    echo "  - $value"
    startTime=$(date +%s%3N)

    K6_PROMETHEUS_RW_SERVER_URL=http://localhost:9090/api/v1/write K6_PROMETHEUS_RW_TREND_AS_NATIVE_HISTOGRAM=true K6_PROMETHEUS_RW_PUSH_INTERVAL=1s K6_PROMETHEUS_RW_TREND_STATS="p(95),p(99),min,max,avg" OPERATION=$key SCENARIO=$value k6 run -o experimental-prometheus-rw ./stress.ts --tag testid="$RUNTIME-$key-$value-stress";

    endTime=$(date +%s%3N)

    data="{
        \"time\": $startTime,
        \"timeEnd\": $endTime,
        \"tags\": [\"$RUNTIME\", \"$key-$value\", \"stress\"],
        \"text\": \"$key-$value\"
      }"
    curl -X POST http://localhost:3000/api/annotations \
      -H "Content-Type: application/json" \
      -d "$data" \
      --basic -u admin:admin

    sleep 60  # Let it "cool down" for a minute
    docker compose restart php-fpm php-octane swift swift-reerjson
    docker compose restart php-nginx
    sleep 30

  done
done

