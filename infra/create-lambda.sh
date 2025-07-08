#!/bin/bash

set -e

FUNCTION_NAME="ContactFormHandler"
ROLE_ARN=$(aws iam get-role --role-name lambda-dynamodb-role --query 'Role.Arn' --output text)

echo "Zipping Lambda function..."
cd backend
zip function.zip lambda_function.js
cd ..

echo "Deploying Lambda function..."

aws lambda create-function \
  --function-name $FUNCTION_NAME \
  --runtime nodejs18.x \
  --handler lambda_function.handler \
  --role $ROLE_ARN \
  --zip-file fileb://backend/function.zip

echo "Lambda function deployed: $FUNCTION_NAME"
