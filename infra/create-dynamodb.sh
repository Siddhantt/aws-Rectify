#!/bin/bash

set -e

TABLE_NAME="ContactMessages"
REGION="ap-south-1"

echo "🔍 Checking if DynamoDB table '$TABLE_NAME' already exists..."
if aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$REGION" > /dev/null 2>&1; then
  echo "✅ Table '$TABLE_NAME' already exists. Skipping creation."
else
  echo "🗄️ Creating DynamoDB table: $TABLE_NAME..."
  aws dynamodb create-table \
    --table-name "$TABLE_NAME" \
    --attribute-definitions AttributeName=email,AttributeType=S \
    --key-schema AttributeName=email,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION"

  echo "⏳ Waiting for table to be ACTIVE..."
  aws dynamodb wait table-exists \
    --table-name "$TABLE_NAME" \
    --region "$REGION"

  echo "✅ Table '$TABLE_NAME' created successfully!"
fi
