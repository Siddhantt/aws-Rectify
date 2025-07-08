#!/bin/bash

set -e

BUCKET_NAME="siddhant-portfolio-2025"
AWS_REGION="ap-south-1"  # Mumbai region

# Create S3 bucket
echo "Creating S3 bucket: $BUCKET_NAME..."
if [[ "$AWS_REGION" == "us-east-1" ]]; then
  # No LocationConstraint needed for us-east-1
  aws s3api create-bucket --bucket $BUCKET_NAME --region $AWS_REGION
else
  # Add LocationConstraint for other regions like ap-south-1 (Mumbai)
  aws s3api create-bucket \
    --bucket $BUCKET_NAME \
    --region $AWS_REGION \
    --create-bucket-configuration LocationConstraint=$AWS_REGION
fi

echo "Disabling block public access..."
aws s3api delete-public-access-block \
  --bucket $BUCKET_NAME || echo "Failed to delete block public access. It might not exist."

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
echo "http://$BUCKET_NAME.s3-website-$AWS_REGION.amazonaws.com"