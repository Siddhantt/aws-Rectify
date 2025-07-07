#!/bin/bash

set -e

BUCKET_NAME="siddhant-portfolio-2025"

echo "Creating S3 bucket: $BUCKET_NAME..."
aws s3api create-bucket \
  --bucket $BUCKET_NAME \
  --region us-east-1

echo "Enabling static website hosting..."
aws s3 website s3://$BUCKET_NAME/ \
  --index-document index.html \
  --error-document error.html

echo "Applying public-read policy..."
aws s3api put-bucket-policy \
  --bucket $BUCKET_NAME \
  --policy file://infra/bucket-policy.json

echo "Syncing website content..."
aws s3 sync ./frontend s3://$BUCKET_NAME/ --delete

echo "S3 website deployed at:"
echo "http://$BUCKET_NAME.s3-website-us-east-1.amazonaws.com"
