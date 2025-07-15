#!/bin/bash
set -e

# === Config ===
FUNCTION_NAME="${FUNCTION_NAME:-myLambdaFunction}"
REGION="ap-south-1"
API_NAME="ContactAPI"

# === Automatically fetch AWS account ID ===
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "🔐 Using AWS Account ID: $ACCOUNT_ID"

# === Check if API exists ===
echo "🔍 Checking if API '$API_NAME' already exists..."
API_ID=$(aws apigateway get-rest-apis \
  --region $REGION \
  --query "items[?name=='$API_NAME'].id" \
  --output text)

if [[ -z "$API_ID" ]]; then
  echo "📡 API not found. Creating '$API_NAME'..."
  API_ID=$(aws apigateway create-rest-api \
    --name "$API_NAME" \
    --region $REGION \
    --query 'id' \
    --output text)
else
  echo "✅ API '$API_NAME' already exists with ID: $API_ID"
fi

echo "🌐 Using API ID: $API_ID"

# === Get root resource ID ===
PARENT_ID=$(aws apigateway get-resources \
  --rest-api-id $API_ID \
  --region $REGION \
  --query 'items[?path==`/`].id' \
  --output text)

# === Create /contact resource if not exists ===
RESOURCE_ID=$(aws apigateway get-resources \
  --rest-api-id $API_ID \
  --region $REGION \
  --query "items[?path=='/contact'].id" \
  --output text)

if [[ -z "$RESOURCE_ID" ]]; then
  echo "📁 Creating /contact resource..."
  RESOURCE_ID=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $PARENT_ID \
    --path-part contact \
    --region $REGION \
    --query 'id' \
    --output text)
else
  echo "✅ /contact resource already exists with ID: $RESOURCE_ID"
fi

# === Add POST method ===
echo "🔧 Configuring POST method..."
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method POST \
  --authorization-type NONE \
  --region $REGION || echo "⚠️ POST method may already exist."

# === Integrate POST with Lambda ===
LAMBDA_ARN=$(aws lambda get-function \
  --function-name $FUNCTION_NAME \
  --region $REGION \
  --query 'Configuration.FunctionArn' \
  --output text)

echo "🔌 Setting POST integration with Lambda..."
aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method POST \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/$LAMBDA_ARN/invocations \
  --region $REGION

# === CORS: OPTIONS method ===
echo "🔧 Configuring OPTIONS method for CORS..."
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method OPTIONS \
  --authorization-type NONE \
  --region $REGION || echo "⚠️ OPTIONS method may already exist."

aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method OPTIONS \
  --type MOCK \
  --region $REGION

aws apigateway put-method-response \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method OPTIONS \
  --status-code 200 \
  --response-parameters "method.response.header.Access-Control-Allow-Headers=true,method.response.header.Access-Control-Allow-Origin=true,method.response.header.Access-Control-Allow-Methods=true" \
  --region $REGION || echo "⚠️ OPTIONS method response may already exist."

aws apigateway put-integration-response \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method OPTIONS \
  --status-code 200 \
  --response-parameters "method.response.header.Access-Control-Allow-Headers='Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',method.response.header.Access-Control-Allow-Origin='*',method.response.header.Access-Control-Allow-Methods='POST,OPTIONS'" \
  --region $REGION || echo "⚠️ OPTIONS integration response may already exist."

# === Lambda permission for API Gateway ===
echo "🔐 Granting Lambda invoke permission to API Gateway..."
aws lambda add-permission \
  --function-name $FUNCTION_NAME \
  --statement-id apigateway-access-$(date +%s) \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --region $REGION \
  --source-arn arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*/POST/contact || echo "⚠️ Permission may already exist."

# === Deploy API ===
echo "🚀 Deploying API to stage 'prod'..."
aws apigateway create-deployment \
  --rest-api-id $API_ID \
  --stage-name prod \
  --region $REGION

# === Export API URL to file ===
echo "🔗 Exporting API endpoint to .tmp_api_url.txt for frontend injection..."
echo "https://$API_ID.execute-api.$REGION.amazonaws.com/prod/contact" > .tmp_api_url.txt

# === Final output ===
echo "✅ API deployed successfully!"
echo "🔗 Endpoint: https://$API_ID.execute-api.$REGION.amazonaws.com/prod/contact"