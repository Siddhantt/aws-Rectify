#!/bin/bash
set -e

API_NAME="ContactAPI"
RESOURCE_PATH="contact"
REGION="ap-south-1"

echo "🔍 Checking for existing API '$API_NAME'..."
API_ID=$(aws apigateway get-rest-apis --query "items[?name=='$API_NAME'].id" --output text)

if [ -n "$API_ID" ]; then
  echo "⚠️ API '$API_NAME' exists. Deleting it..."
  aws apigateway delete-rest-api --rest-api-id "$API_ID"
  sleep 2
fi

echo "🚀 Creating new API '$API_NAME'..."
API_ID=$(aws apigateway create-rest-api --name "$API_NAME" --query "id" --output text)
echo "✅ Created API ID: $API_ID"

ROOT_ID=$(aws apigateway get-resources --rest-api-id "$API_ID" --query "items[?path=='/'].id" --output text)

echo "📁 Creating /$RESOURCE_PATH resource..."
CONTACT_ID=$(aws apigateway create-resource \
  --rest-api-id "$API_ID" \
  --parent-id "$ROOT_ID" \
  --path-part "$RESOURCE_PATH" \
  --query "id" --output text)

echo ""
echo "📌 Save and export these variables before running the next script:"
echo "export API_ID=$API_ID"
echo "export CONTACT_ID=$CONTACT_ID"

