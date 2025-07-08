#!/bin/bash

set -e

TABLE_NAME="ContactMessages"

echo "Creating DynamoDB table: $TABLE_NAME..."

aws dynamodb create-table \
  --table-name $TABLE_NAME \
  --attribute-definitions AttributeName=email,AttributeType=S \
  --key-schema AttributeName=email,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

echo "DynamoDB table created."
