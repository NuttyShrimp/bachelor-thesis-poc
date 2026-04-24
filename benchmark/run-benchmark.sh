#! /usr/bin/env bash

result=$(curl "http://$1/api/benchmarks/run/$2")
echo "$result"

echo "$result" | jq -c ".benchmarks.$2[]" | while read -r scenario; do
  startTime=$(($(echo $scenario | jq ".start_time_ms") * 1000))
  endTime=$(($(echo $scenario | jq ".end_time_ms") * 1000))
  data="{
      \"time\": $startTime,
      \"timeEnd\": $endTime,
      \"tags\": [$(echo $result | jq ".meta.runtime"), \"$2\"],
      \"text\": $(echo $scenario | jq '.operation')
    }"
  echo $data
  curl -X POST http://localhost:3000/api/annotations \
    -H "Content-Type: application/json" \
    -d "$data" \
    --basic -u admin:admin
done

