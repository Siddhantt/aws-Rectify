#!/bin/bash

set -e

BUCKET_NAME="siddhant-portfolio-2025"
AWS_REGION="ap-south-1"  # Mumbai region

# Create bucket only if it doesn't exist
if ! aws s3api head-bucket --bucket $BUCKET_NAME 2>/dev/null; then
  echo "🪣 Creating S3 bucket: $BUCKET_NAME..."
  if [[ "$AWS_REGION" == "us-east-1" ]]; then
    aws s3api create-bucket --bucket $BUCKET_NAME --region $AWS_REGION
  else
    aws s3api create-bucket \
      --bucket $BUCKET_NAME \
      --region $AWS_REGION \
      --create-bucket-configuration LocationConstraint=$AWS_REGION
  fi

  echo "🔓 Disabling block public access..."
  aws s3api delete-public-access-block --bucket $BUCKET_NAME || echo "Block public access already removed."

  echo "🌐 Enabling static website hosting..."
  aws s3 website s3://$BUCKET_NAME/ \
    --index-document index.html \
    --error-document error.html

  echo "🔐 Applying public-read policy..."
  aws s3api put-bucket-policy \
    --bucket $BUCKET_NAME \
    --policy file://infra/bucket-policy.json
else
  echo "✅ S3 bucket $BUCKET_NAME already exists. Skipping creation."
fi

# ✅ Always sync latest frontend files
echo "🚀 Uploading latest frontend files to S3..."
aws s3 sync ./frontend s3://$BUCKET_NAME/ --delete

echo "🌍 Website URL:"
echo "http://$BUCKET_NAME.s3-website-$AWS_REGION.amazonaws.com"
