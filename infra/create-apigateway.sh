#!/bin/bash

set -e

FUNCTION_NAME="myLambdaFunction"  # Update the Lambda function name

echo "Creating API Gateway REST API..."
API_ID=$(aws apigateway create-rest-api \
  --name "ContactAPI" \
  --query 'id' \
  --output text)

PARENT_ID=$(aws apigateway get-resources \
  --rest-api-id $API_ID \
  --query 'items[0].id' \
  --output text)

echo "Creating resource /contact..."
RESOURCE_ID=$(aws apigateway create-resource \
  --rest-api-id $API_ID \
  --parent-id $PARENT_ID \
  --path-part contact \
  --query 'id' \
  --output text)

echo "Creating POST method..."
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method POST \
  --authorization-type NONE

echo "Integrating with Lambda..."
LAMBDA_ARN=$(aws lambda get-function --function-name $FUNCTION_NAME --query 'Configuration.FunctionArn' --output text)

aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method POST \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri arn:aws:apigateway:ap-south-1:lambda:path/2015-03-31/functions/$LAMBDA_ARN/invocations

echo "Granting API Gateway permissions to invoke Lambda..."
aws lambda add-permission \
  --function-name $FUNCTION_NAME \
  --statement-id apigateway-access \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn arn:aws:execute-api:ap-south-1:*:$API_ID/*/POST/contact

echo "Deploying API..."
aws apigateway create-deployment \
  --rest-api-id $API_ID \
  --stage-name prod

echo "API URL: https://$API_ID.execute-api.ap-south-1.amazonaws.com/prod/contact"
