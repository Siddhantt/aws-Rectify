#!/bin/bash
set -e

FUNCTION_NAME="myLambdaFunction"
ACCOUNT_ID="326641642949"
REGION="ap-south-1"
RESOURCE_PATH="contact"

# Ensure API_ID and CONTACT_ID are set
if [ -z "$API_ID" ] || [ -z "$CONTACT_ID" ]; then
  echo "❌ ERROR: API_ID or CONTACT_ID is not set."
  echo "👉 Run 'source create-api.sh' first or manually export them."
  exit 1
fi

########################
# POST METHOD + Lambda
########################

echo "🔧 Configuring POST method..."
aws apigateway put-method \
  --rest-api-id "$API_ID" \
  --resource-id "$CONTACT_ID" \
  --http-method POST \
  --authorization-type "NONE"

aws apigateway put-integration \
  --rest-api-id "$API_ID" \
  --resource-id "$CONTACT_ID" \
  --http-method POST \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/arn:aws:lambda:$REGION:$ACCOUNT_ID:function:$FUNCTION_NAME/invocations"

echo "🛠 Adding POST method response (CORS headers)..."
aws apigateway put-method-response \
  --rest-api-id "$API_ID" \
  --resource-id "$CONTACT_ID" \
  --http-method POST \
  --status-code 200 \
  --response-parameters '{
    "method.response.header.Access-Control-Allow-Origin": true,
    "method.response.header.Access-Control-Allow-Methods": true,
    "method.response.header.Access-Control-Allow-Headers": true
  }' \
  --response-models '{"application/json":"Empty"}'

aws apigateway put-integration-response \
  --rest-api-id "$API_ID" \
  --resource-id "$CONTACT_ID" \
  --http-method POST \
  --status-code 200 \
  --response-parameters '{
    "method.response.header.Access-Control-Allow-Headers": "'\''Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'\''",
    "method.response.header.Access-Control-Allow-Methods": "'\''POST,OPTIONS'\''",
    "method.response.header.Access-Control-Allow-Origin": "'\''*'\''"
  }' \
  --response-templates '{"application/json": ""}'

########################
# OPTIONS METHOD (CORS)
########################

echo "🔧 Adding OPTIONS method for CORS..."
aws apigateway put-method \
  --rest-api-id "$API_ID" \
  --resource-id "$CONTACT_ID" \
  --http-method OPTIONS \
  --authorization-type "NONE"

aws apigateway put-integration \
  --rest-api-id "$API_ID" \
  --resource-id "$CONTACT_ID" \
  --http-method OPTIONS \
  --type MOCK \
  --request-templates '{"application/json":"{\"statusCode\": 200}"}'

aws apigateway put-method-response \
  --rest-api-id "$API_ID" \
  --resource-id "$CONTACT_ID" \
  --http-method OPTIONS \
  --status-code 200 \
  --response-parameters '{
    "method.response.header.Access-Control-Allow-Headers": true,
    "method.response.header.Access-Control-Allow-Methods": true,
    "method.response.header.Access-Control-Allow-Origin": true
  }' \
  --response-models '{"application/json":"Empty"}'

aws apigateway put-integration-response \
  --rest-api-id "$API_ID" \
  --resource-id "$CONTACT_ID" \
  --http-method OPTIONS \
  --status-code 200 \
  --response-parameters '{
    "method.response.header.Access-Control-Allow-Headers": "'\''Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'\''",
    "method.response.header.Access-Control-Allow-Methods": "'\''POST,OPTIONS'\''",
    "method.response.header.Access-Control-Allow-Origin": "'\''*'\''"
  }' \
  --response-templates '{"application/json": ""}'

########################
# Lambda Permissions
########################

echo "🔐 Updating Lambda permissions..."
aws lambda remove-permission \
  --function-name "$FUNCTION_NAME" \
  --statement-id apigateway-access \
  2>/dev/null || true

aws lambda add-permission \
  --function-name "$FUNCTION_NAME" \
  --statement-id apigateway-access \
  --action "lambda:InvokeFunction" \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*/POST/$RESOURCE_PATH"

########################
# Deployment
########################

echo "🚢 Deploying to stage 'prod'..."
aws apigateway create-deployment \
  --rest-api-id "$API_ID" \
  --stage-name prod

echo "✅ API configuration complete!"
echo "🌐 Live endpoint:"
echo "https://$API_ID.execute-api.$REGION.amazonaws.com/prod/$RESOURCE_PATH"
