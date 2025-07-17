#!/bin/bash
set -e

FUNCTION_NAME="myLambdaFunction"
ACCOUNT_ID="326641642949"
REGION="ap-south-1"
API_NAME="ContactAPI"
RESOURCE_PATH="contact"

echo "Using AWS Account ID: $ACCOUNT_ID"
echo "Checking if API '$API_NAME' already exists..."

API_ID=$(aws apigateway get-rest-apis --query "items[?name=='$API_NAME'].id" --output text)

if [ -z "$API_ID" ]; then
  echo "API '$API_NAME' not found. Creating..."
  API_ID=$(aws apigateway create-rest-api --name "$API_NAME" --query "id" --output text)
fi

echo "Using existing API ID: $API_ID"

# Get root resource ID
ROOT_ID=$(aws apigateway get-resources --rest-api-id "$API_ID" --query "items[?path=='/'].id" --output text)

# Check if /contact exists
CONTACT_ID=$(aws apigateway get-resources --rest-api-id "$API_ID" \
  --query "items[?path=='/$RESOURCE_PATH'].id" --output text)

if [ -n "$CONTACT_ID" ]; then
  echo "/$RESOURCE_PATH resource already exists. Deleting..."

  for method in POST OPTIONS; do
    aws apigateway delete-method --rest-api-id "$API_ID" \
      --resource-id "$CONTACT_ID" --http-method "$method" 2>/dev/null || true
  done

  aws apigateway delete-resource --rest-api-id "$API_ID" --resource-id "$CONTACT_ID"
fi

# Recreate /contact
echo "Creating /$RESOURCE_PATH..."
CONTACT_ID=$(aws apigateway create-resource \
  --rest-api-id "$API_ID" \
  --parent-id "$ROOT_ID" \
  --path-part "$RESOURCE_PATH" \
  --query "id" --output text)

########################
# POST METHOD + Lambda
########################

echo "Configuring POST method..."
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

echo "Adding POST method response (CORS headers)..."
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

echo "Adding POST integration response (CORS headers)..."
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

echo "Adding CORS (OPTIONS method)..."
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
# PERMISSION + DEPLOY
########################

echo "Granting Lambda invoke permission to API Gateway..."
aws lambda add-permission \
  --function-name "$FUNCTION_NAME" \
  --statement-id "apigateway-access-$(date +%s)" \
  --action "lambda:InvokeFunction" \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*/POST/$RESOURCE_PATH" \
  2>/dev/null || true

echo "Deploying to stage 'prod'..."
aws apigateway create-deployment \
  --rest-api-id "$API_ID" \
  --stage-name prod

echo "✅ API setup completed."
echo "🌐 Endpoint:"
echo "https://$API_ID.execute-api.$REGION.amazonaws.com/prod/$RESOURCE_PATH"
