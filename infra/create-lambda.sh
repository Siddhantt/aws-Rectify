#!/bin/bash

set -e

FUNCTION_NAME="ContactFormHandler"
ROLE_ARN=$(aws iam get-role --role-name lambda-dynamodb-role --query 'Role.Arn' --output text)

echo "Zipping Lambda function..."
cd backend
zip function.zip lambda_function.py  # Make sure to zip the Python function file
cd ..

echo "Deploying Lambda function..."

aws lambda create-function \
  --function-name $FUNCTION_NAME \
  --runtime python3.8 \  # Change runtime to python3.8 or another supported version
  --handler lambda_function.lambda_handler \  # This should be your file name and function name
  --role $ROLE_ARN \
  --zip-file fileb://backend/function.zip

echo "Lambda function deployed: $FUNCTION_NAME"
