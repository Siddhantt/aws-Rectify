#!/bin/bash

set -e

REGION="ap-south-1"
RESOURCE_PATH="contact"
API_NAME="ContactAPI"  # Replace with your actual API Gateway name

echo "🔍 Fetching API ID for API named '$API_NAME'..."
API_ID=$(aws apigateway get-rest-apis \
  --region $REGION \
  --query "items[?name=='$API_NAME'].id" \
  --output text)

if [ -z "$API_ID" ]; then
  echo "❌ API '$API_NAME' not found."
  exit 1
fi
echo "✅ Found API ID: $API_ID"

echo "🔍 Fetching resource ID for /$RESOURCE_PATH..."
RESOURCE_ID=$(aws apigateway get-resources \
  --rest-api-id $API_ID \
  --region $REGION \
  --query "items[?path=='/$RESOURCE_PATH'].id" \
  --output text)

if [ -z "$RESOURCE_ID" ]; then
  echo "❌ Resource /$RESOURCE_PATH not found."
  exit 1
fi
echo "✅ Found resource ID: $RESOURCE_ID"

echo "🔧 Ensuring OPTIONS method exists..."
aws apigateway get-method \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method OPTIONS \
  --region $REGION >/dev/null 2>&1 || {
  aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method OPTIONS \
    --authorization-type "NONE" \
    --region $REGION
}

echo "🔧 Ensuring method response for OPTIONS exists..."
aws apigateway get-method-response \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method OPTIONS \
  --status-code 200 \
  --region $REGION >/dev/null 2>&1 || {
  aws apigateway put-method-response \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters '{
      "method.response.header.Access-Control-Allow-Headers": true,
      "method.response.header.Access-Control-Allow-Methods": true,
      "method.response.header.Access-Control-Allow-Origin": true
    }' \
    --response-models '{"application/json":"Empty"}' \
    --region $REGION
}

echo "🔧 Ensuring OPTIONS integration is set..."
aws apigateway get-integration \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method OPTIONS \
  --region $REGION >/dev/null 2>&1 || {
  aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method OPTIONS \
    --type MOCK \
    --request-templates '{"application/json": "{\"statusCode\": 200}"}' \
    --region $REGION
}

echo "🔧 Ensuring integration response for OPTIONS exists..."
aws apigateway get-integration-response \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method OPTIONS \
  --status-code 200 \
  --region $REGION >/dev/null 2>&1 || {
  aws apigateway put-integration-response \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters '{
      "method.response.header.Access-Control-Allow-Headers": "'\''Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'\''",
      "method.response.header.Access-Control-Allow-Methods": "'\''OPTIONS,POST'\''",
      "method.response.header.Access-Control-Allow-Origin": "'\''*'\''"
    }' \
    --response-templates '{"application/json":""}' \
    --region $REGION
}

echo "🚀 Deploying updated API Gateway..."
aws apigateway create-deployment \
  --rest-api-id $API_ID \
  --stage-name prod \
  --region $REGION

echo "✅ CORS enabled successfully for /$RESOURCE_PATH"