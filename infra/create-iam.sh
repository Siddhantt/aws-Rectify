#!/bin/bash

set -e

ROLE_NAME="lambda-dynamodb-role"
TRUST_POLICY_FILE="infra/trust-policy.json"
PERMISSIONS_POLICY_FILE="infra/permissions-policy.json"
REGION="ap-south-1"

echo "🔐 Checking required policy files..."
if [[ ! -f "$TRUST_POLICY_FILE" || ! -f "$PERMISSIONS_POLICY_FILE" ]]; then
  echo "❌ Missing trust or permissions policy JSON in infra/"
  exit 1
fi

# Check if the IAM role already exists
if aws iam get-role --role-name "$ROLE_NAME" > /dev/null 2>&1; then
  echo "✅ IAM role '$ROLE_NAME' already exists. Skipping creation."
else
  echo "🔧 Creating IAM role for Lambda..."
  aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document file://$TRUST_POLICY_FILE

  echo "✅ IAM role '$ROLE_NAME' created."
fi

# Attach policy (put-role-policy overwrites if already exists with same name)
echo "🔗 Attaching inline policy to allow Lambda to access DynamoDB..."
aws iam put-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-name lambda-dynamodb-access \
  --policy-document file://$PERMISSIONS_POLICY_FILE

# Export the Role ARN for later use (in Lambda creation)
ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text)
echo "$ROLE_ARN" > .tmp_role_arn.txt

echo "✅ IAM Role setup complete. ARN: $ROLE_ARN"