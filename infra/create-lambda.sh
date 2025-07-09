#!/bin/bash

set -e

# Lambda function details
FUNCTION_NAME="myLambdaFunction"
ZIP_FILE="lambda_function.zip"
ROLE_ARN="arn:aws:iam::326641642949:role/lambda-dynamodb-role"

# ✅ Ensure lambda_function.py exists
echo "🔍 Checking if backend/lambda_function.py exists..."
if [ ! -f backend/lambda_function.py ]; then
  echo "❌ Error: backend/lambda_function.py not found!"
  exit 1
fi

# ✅ Zip the function with correct structure (flat root-level)
echo "📦 Zipping Lambda function..."
cd backend
zip -r ../$ZIP_FILE lambda_function.py > /dev/null
cd ..

# ✅ List contents of the zip to verify structure
echo "📂 Contents of zip archive:"
unzip -l $ZIP_FILE

# ✅ Create Lambda function
echo "🚀 Deploying Lambda function..."
aws lambda create-function \
  --function-name "$FUNCTION_NAME" \
  --zip-file fileb://$ZIP_FILE \
  --handler lambda_function.lambda_handler \
  --runtime python3.8 \
  --role "$ROLE_ARN"

# ✅ Optional: remove zip to keep workspace clean
rm -f $ZIP_FILE

echo "✅ Lambda function '$FUNCTION_NAME' deployed successfully."
