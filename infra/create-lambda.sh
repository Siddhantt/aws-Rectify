#!/bin/bash

set -e

# === Config ===
FUNCTION_NAME="myLambdaFunction"
ZIP_FILE="lambda_function.zip"
ROLE_NAME="lambda-dynamodb-role"
REGION="ap-south-1"
ROLE_FILE=".tmp_role_arn.txt"

# === Get IAM Role ARN ===
if [[ -f "$ROLE_FILE" ]]; then
  ROLE_ARN=$(cat "$ROLE_FILE")
  echo "✅ Loaded IAM role ARN from $ROLE_FILE"
else
  echo "⚠️ $ROLE_FILE not found. Falling back to generate ARN dynamically..."
  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
  ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
  echo "ℹ️ Using fallback IAM role ARN: $ROLE_ARN"
fi

# === Ensure lambda_function.py exists ===
echo "🔍 Checking if backend/lambda_function.py exists..."
if [ ! -f backend/lambda_function.py ]; then
  echo "❌ Error: backend/lambda_function.py not found!"
  exit 1
fi

# === Zip the function ===
echo "📦 Zipping Lambda function..."
cd backend
zip -r ../$ZIP_FILE lambda_function.py > /dev/null
cd ..

# === Show zip contents ===
echo "📂 Contents of zip archive:"
unzip -l $ZIP_FILE

# === Create or Update Lambda ===
if aws lambda get-function --function-name "$FUNCTION_NAME" --region "$REGION" > /dev/null 2>&1; then
  echo "🔁 Lambda exists. Updating code..."
  aws lambda update-function-code \
    --function-name "$FUNCTION_NAME" \
    --zip-file fileb://$ZIP_FILE \
    --region "$REGION"
else
  echo "🚀 Creating new Lambda function..."
  aws lambda create-function \
    --function-name "$FUNCTION_NAME" \
    --zip-file fileb://$ZIP_FILE \
    --handler lambda_function.lambda_handler \
    --runtime python3.8 \
    --role "$ROLE_ARN" \
    --region "$REGION"
fi

# === Clean up ===
rm -f "$ZIP_FILE"

echo "✅ Lambda function '$FUNCTION_NAME' is deployed and up to date in region '$REGION'."