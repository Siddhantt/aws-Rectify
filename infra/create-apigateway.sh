#!/bin/bash

set -e

FUNCTION_NAME="myLambdaFunction"
ACCOUNT_ID="326641642949"
REGION="ap-south-1"

echo "Creating API Gateway REST API..."
API_ID=$(aws apigateway create-rest-api \
  --name "ContactAPI" \
  --region $REGION \
  --query 'id' \
  --output text)

echo "API ID: $API_ID"

# Get root resource ID
PARENT_ID=$(aws apigateway get-resources \
  --rest-api-id $API_ID \
  --region $REGION \
  --query 'items[0].id' \
  --output text)

# Create /contact resource
echo "Creating resource /contact..."
RESOURCE_ID=$(aws apigateway create-resource \
  --rest-api-id $API_ID \
  --parent-id $PARENT_ID \
  --path-part contact \
  --region $REGION \
  --query 'id' \
  --output text)

echo "RESOURCE ID: $RESOURCE_ID"

# Create POST method
echo "Creating POST method..."
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method POST \
  --authorization-type NONE \
  --region $REGION

# Lambda ARN
echo "Fetching Lambda ARN..."
LAMBDA_ARN=$(aws lambda get-function \
  --function-name $FUNCTION_NAME \
  --region $REGION \
  --query 'Configuration.FunctionArn' \
  --output text)

# Integrate API Gateway with Lambda
echo "Integrating with Lambda..."
aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method POST \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/$LAMBDA_ARN/invocations \
  --region $REGION

# Add Lambda invoke permission for API Gateway
echo "Granting API Gateway permission to invoke Lambda..."
aws lambda add-permission \
  --function-name $FUNCTION_NAME \
  --statement-id apigateway-access-$(date +%s) \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --region $REGION \
  --source-arn arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*/POST/contact

# Deploy the API
echo "Deploying API..."
aws apigateway create-deployment \
  --rest-api-id $API_ID \
  --stage-name prod \
  --region $REGION

# Print public API URL
echo "✅ API is ready:"
echo "🔗 https://$API_ID.execute-api.$REGION.amazonaws.com/prod/contact"
