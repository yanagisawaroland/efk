#!/bin/bash
ES_URL="http://10.20.50.71:32304"

echo "=== 等待 ES 就绪 ==="
until curl -s "$ES_URL/_cluster/health" | grep -q '"status":"green"\|"status":"yellow"'; do
  echo "ES 未就绪，等待 5s..."
  sleep 5
done
echo "ES 已就绪"

echo "=== 创建 ILM 策略（90天删除）==="
curl -s -X PUT "$ES_URL/_ilm/policy/k8s-logs-policy" \
  -H "Content-Type: application/json" \
  -d '{
    "policy": {
      "phases": {
        "hot": {
          "actions": {
            "rollover": {
              "max_size": "5GB",
              "max_age": "1d"
            }
          }
        },
        "delete": {
          "min_age": "90d",
          "actions": {
            "delete": {}
          }
        }
      }
    }
  }'
echo ""

echo "=== 创建 Index Template ==="
curl -s -X PUT "$ES_URL/_template/k8s-logs" \
  -H "Content-Type: application/json" \
  -d '{
    "index_patterns": ["k8s-logs-*"],
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0,
      "lifecycle.name": "k8s-logs-policy",
      "lifecycle.rollover_alias": "k8s-logs"
    }
  }'
echo ""
echo "=== ILM 配置完成 ==="
