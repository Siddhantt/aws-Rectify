#!/bin/bash

set -e

BUCKET_NAME="siddhant-portfolio-2025"
AWS_REGION="ap-south-1"  # Specify your region here

# Create the S3 bucket with the specified region
echo "Creating S3 bucket: $BUCKET_NAME in region: $AWS_REGION..."
aws s3api create-bucket \
  --bucket $BUCKET_NAME \
  --region $AWS_REGION \
  --create-bucket-configuration LocationConstraint=$AWS_REGION

# Disable block public access
echo "Disabling block public access..."
aws s3api delete-bucket-public-access-block \
  --bucket $BUCKET_NAME

# Enabling static website hosting
echo "Enabling static website hosting..."
aws s3 website s3://$BUCKET_NAME/ \
  --index-document index.html \
  --error-document error.html

# Applying bucket policy
echo "Applying bucket policy..."
aws s3api put-bucket-policy \
  --bucket $BUCKET_NAME \
  --policy file://./infra/bucket-policy.json

# Syncing website content
echo "Syncing website content..."
aws s3 sync ./frontend s3://$BUCKET_NAME/ --delete

echo "S3 website deployed at:"
echo "http://$BUCKET_NAME.s3-website-$AWS_REGION.amazonaws.com"
