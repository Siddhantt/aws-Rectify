#!/bin/bash
set -e

FUNCTION_NAME="myLambdaFunction"
ACCOUNT_ID="326641642949"
REGION="ap-south-1"
API_NAME="ContactAPI"
STAGE_NAME="prod"

echo "Using AWS Account ID: $ACCOUNT_ID"

# Get or create API
echo "Checking if API '$API_NAME' already exists..."
API_ID=$(aws apigateway get-rest-apis \
  --query "items[?name=='$API_NAME'].id" \
  --output text)

if [ -z "$API_ID" ]; then
  echo "API not found. Creating '$API_NAME'..."
  API_ID=$(aws apigateway create-rest-api \
    --name "$API_NAME" \
    --query "id" \
    --output text)
else
  echo "Using existing API ID: $API_ID"
fi

# Get root resource ID
ROOT_ID=$(aws apigateway get-resources \
  --rest-api-id "$API_ID" \
  --query "items[?path=='/'].id" \
  --output text)

# Check if /contact already exists
CONTACT_ID=$(aws apigateway get-resources \
  --rest-api-id "$API_ID" \
  --query "items[?path=='/contact'].id" \
  --output text)

if [ -z "$CONTACT_ID" ]; then
  echo "Creating /contact resource..."
  CONTACT_ID=$(aws apigateway create-resource \
    --rest-api-id "$API_ID" \
    --parent-id "$ROOT_ID" \
    --path-part "contact" \
    --query "id" \
    --output text)
else
  echo "/contact resource already exists. Using existing ID: $CONTACT_ID"
fi

# Configure POST method
echo "Configuring POST method..."
aws apigateway put-method \
  --rest-api-id "$API_ID" \
  --resource-id "$CONTACT_ID" \
  --http-method POST \
  --authorization-type "NONE" \
  --region "$REGION" || echo "POST method already exists"

# Set Lambda integration
echo "Setting POST integration with Lambda..."
aws apigateway put-integration \
  --rest-api-id "$API_ID" \
  --resource-id "$CONTACT_ID" \
  --http-method POST \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/arn:aws:lambda:$REGION:$ACCOUNT_ID:function:$FUNCTION_NAME/invocations" \
  --region "$REGION"

# Add CORS headers to POST response
echo "Adding CORS headers to POST response..."
aws apigateway put-method-response \
  --rest-api-id "$API_ID" \
  --resource-id "$CONTACT_ID" \
  --http-method POST \
  --status-code 200 \
  --response-parameters "method.response.header.Access-Control-Allow-Origin=true" \
  --region "$REGION" || echo "POST method response may already exist."

aws apigateway put-integration-response \
  --rest-api-id "$API_ID" \
  --resource-id "$CONTACT_ID" \
  --http-method POST \
  --status-code 200 \
  --response-parameters '{"method.response.header.Access-Control-Allow-Origin":"'\''*'\''"}' \
  --region "$REGION" || echo "POST integration response may already exist."

# OPTIONS method for CORS
echo "Configuring OPTIONS method for CORS..."
aws apigateway put-method \
  --rest-api-id "$API_ID" \
  --resource-id "$CONTACT_ID" \
  --http-method OPTIONS \
  --authorization-type "NONE" \
  --region "$REGION" || echo "OPTIONS method already exists"

aws apigateway put-integration \
  --rest-api-id "$API_ID" \
  --resource-id "$CONTACT_ID" \
  --http-method OPTIONS \
  --type MOCK \
  --request-templates '{"application/json":"{\"statusCode\": 200}"}' \
  --region "$REGION" || echo "OPTIONS integration already exists"

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
  --region "$REGION" || echo "OPTIONS method response may already exist"

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
  --region "$REGION" || echo "OPTIONS integration response may already exist"

# Add Lambda permission
echo "Granting Lambda invoke permission to API Gateway..."
aws lambda add-permission \
  --function-name "$FUNCTION_NAME" \
  --statement-id "apigateway-access-$(date +%s)" \
  --action "lambda:InvokeFunction" \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*/POST/contact" \
  --region "$REGION" || echo "Lambda permission may already exist"

# Deploy API
echo "Deploying API to stage '$STAGE_NAME'..."
aws apigateway create-deployment \
  --rest-api-id "$API_ID" \
  --stage-name "$STAGE_NAME" \
  --region "$REGION"

# Output endpoint
API_URL="https://${API_ID}.execute-api.${REGION}.amazonaws.com/$STAGE_NAME/contact"
echo "$API_URL" > .tmp_api_url.txt
echo "API setup completed. Endpoint: $API_URL"
