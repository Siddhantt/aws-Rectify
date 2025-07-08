#!/bin/bash

set -e

# Lambda function details
FUNCTION_NAME="myLambdaFunction"
ZIP_FILE="lambda_function.zip"
ROLE_ARN="arn:aws:iam::326641642949:role/lambda-dynamodb-role"  # Use the ARN of your role

# Check if lambda_function.py exists
echo "Checking if lambda_function.py exists..."
if [ ! -f backend/lambda_function.py ]; then
  echo "Error: backend/lambda_function.py not found!"
  exit 1
fi

echo "Zipping Lambda function..."
zip $ZIP_FILE backend/lambda_function.py  # Correct path to lambda_function.py

# List files after zip operation
echo "Listing files after zip operation:"
ls -l $ZIP_FILE

# Debugging Role ARN to ensure it's correctly passed
echo "Role ARN: $ROLE_ARN"

echo "Deploying Lambda function..."
# Create the Lambda function
aws lambda create-function \
  --function-name $FUNCTION_NAME \
  --zip-file fileb://$ZIP_FILE \
  --handler lambda_function.lambda_handler \
  --runtime python3.8 \
  --role $ROLE_ARN
