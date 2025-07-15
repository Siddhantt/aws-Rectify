#!/bin/bash

set -e

# === Config ===
FUNCTION_NAME="myLambdaFunction"
ZIP_FILE="lambda_function.zip"
REGION="ap-south-1"
ROLE_FILE=".tmp_role_arn.txt"

# === Check role file ===
if [ ! -f "$ROLE_FILE" ]; then
  echo "❌ Missing IAM role ARN file: $ROLE_FILE"
  echo "➡️  Run create-iam.sh first."
  exit 1
fi

ROLE_ARN=$(cat "$ROLE_FILE")

# === Check Lambda source ===
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

# === Deploy Lambda ===
if aws lambda get-function --function-name "$FUNCTION_NAME" --region $REGION > /dev/null 2>&1; then
  echo "🔁 Lambda exists. Updating code..."
  aws lambda update-function-code \
    --function-name "$FUNCTION_NAME" \
    --zip-file fileb://$ZIP_FILE \
    --region $REGION
else
  echo "🚀 Creating new Lambda function..."
  aws lambda create-function \
    --function-name "$FUNCTION_NAME" \
    --zip-file fileb://$ZIP_FILE \
    --handler lambda_function.lambda_handler \
    --runtime python3.8 \
    --role "$ROLE_ARN" \
    --region $REGION
fi

# === Output Lambda ARN (optional)
LAMBDA_ARN=$(aws lambda get-function \
  --function-name "$FUNCTION_NAME" \
  --region "$REGION" \
  --query 'Configuration.FunctionArn' \
  --output text)

# === Clean up
rm -f $ZIP_FILE

echo "✅ Lambda function '$FUNCTION_NAME' deployed successfully."
echo "🔗 Lambda ARN: $LAMBDA_ARN"