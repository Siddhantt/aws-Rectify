#!/bin/bash
set -e

echo "🔧 Configuring API Gateway (POST + Lambda + CORS + deploy)..."

API_NAME="ContactAPI"
LAMBDA_NAME="contact-api-handler"
REGION="ap-south-1"

REST_API_ID=$(aws apigateway get-rest-apis --query "items[?name=='${API_NAME}'].id" --output text)
RESOURCE_ID=$(aws apigateway get-resources --rest-api-id "$REST_API_ID" \
  --query "items[?path=='/contact'].id" --output text)

LAMBDA_ARN=$(aws lambda get-function --function-name "$LAMBDA_NAME" \
  --query 'Configuration.FunctionArn' --output text)

# POST method with Lambda proxy integration
echo "🔗 Setting up POST method with Lambda integration..."
aws apigateway put-method \
  --rest-api-id "$REST_API_ID" \
  --resource-id "$RESOURCE_ID" \
  --http-method POST \
  --authorization-type NONE

aws apigateway put-integration \
  --rest-api-id "$REST_API_ID" \
  --resource-id "$RESOURCE_ID" \
  --http-method POST \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations"

aws lambda add-permission \
  --function-name "$LAMBDA_NAME" \
  --statement-id "apigateway-invoke" \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:${REGION}:*:${REST_API_ID}/*/POST/contact" \
  2>/dev/null || echo "✅ Lambda permission already exists."

# OPTIONS method with MOCK for CORS
echo "🌐 Adding CORS support via OPTIONS method..."
aws apigateway put-method \
  --rest-api-id "$REST_API_ID" \
  --resource-id "$RESOURCE_ID" \
  --http-method OPTIONS \
  --authorization-type NONE

aws apigateway put-integration \
  --rest-api-id "$REST_API_ID" \
  --resource-id "$RESOURCE_ID" \
  --http-method OPTIONS \
  --type MOCK \
  --request-templates '{"application/json":"{\"statusCode\": 200}"}'

aws apigateway put-method-response \
  --rest-api-id "$REST_API_ID" \
  --resource-id "$RESOURCE_ID" \
  --http-method OPTIONS \
  --status-code 200 \
  --response-parameters '{"method.response.header.Access-Control-Allow-Origin":true,"method.response.header.Access-Control-Allow-Methods":true,"method.response.header.Access-Control-Allow-Headers":true}' \
  --response-models '{"application/json":"Empty"}'

aws apigateway put-integration-response \
  --rest-api-id "$REST_API_ID" \
  --resource-id "$RESOURCE_ID" \
  --http-method OPTIONS \
  --status-code 200 \
  --response-parameters '{
    "method.response.header.Access-Control-Allow-Origin":"'\''*'\''",
    "method.response.header.Access-Control-Allow-Methods":"'\''POST,OPTIONS'\''",
    "method.response.header.Access-Control-Allow-Headers":"'\''Content-Type'\''"
  }' \
  --response-templates '{"application/json":""}'

# Deployment
echo "🚀 Deploying API to stage 'prod'..."
aws apigateway create-deployment \
  --rest-api-id "$REST_API_ID" \
  --stage-name prod

echo "✅ Deployment complete!"
echo "🌐 Live URL: https://${REST_API_ID}.execute-api.${REGION}.amazonaws.com/prod/contact"
