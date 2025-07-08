#!/bin/bash

set -e

BUCKET_NAME="siddhant-portfolio-2025"
AWS_REGION="ap-south-1"  # Specify your region here

echo "Creating S3 bucket: $BUCKET_NAME in region: $AWS_REGION..."

# Create the S3 bucket with the specified region
aws s3api create-bucket \
  --bucket $BUCKET_NAME \
  --region $AWS_REGION \
  --create-bucket-configuration LocationConstraint=$AWS_REGION

echo "Enabling static website hosting..."
aws s3 website s3://$BUCKET_NAME/ \
  --index-document index.html \
  --error-document error.html

echo "Applying public-read policy..."
aws s3api put-bucket-policy \
  --bucket $BUCKET_NAME \
  --policy file://bucket-policy.json

echo "Syncing website content..."
aws s3 sync ./frontend s3://$BUCKET_NAME/ --delete

echo "S3 website deployed at:"
echo "http://$BUCKET_NAME.s3-website-$AWS_REGION.amazonaws.com"
