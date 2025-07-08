#!/bin/bash

set -e

FUNCTION_NAME="myLambdaFunction"
ZIP_FILE="lambda_function.zip"
ROLE_ARN="arn:aws:iam::326641642949:role/lambda-dynamodb-role"  # Use the ARN of your role

echo "Zipping Lambda function..."
zip $ZIP_FILE backend/lambda_function.py  # Correct path to lambda_function.py

echo "Deploying Lambda function..."
aws lambda create-function \
  --function-name $FUNCTION_NAME \
  --zip-file fileb://$ZIP_FILE \
  --handler lambda_function.lambda_handler \
  --runtime python3.8 \
  --role $ROLE_ARN
