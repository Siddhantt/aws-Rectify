#!/bin/bash

set -e

ROLE_NAME="lambda-dynamodb-role"

echo "Creating IAM role for Lambda..."

aws iam create-role \
  --role-name $ROLE_NAME \
  --assume-role-policy-document file://infra/trust-policy.json

echo "Attaching inline policy to allow Lambda to access DynamoDB..."

aws iam put-role-policy \
  --role-name $ROLE_NAME \
  --policy-name lambda-dynamodb-access \
  --policy-document file://infra/permissions-policy.json

echo "IAM Role created and policy attached."
