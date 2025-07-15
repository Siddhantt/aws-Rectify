#!/bin/bash

set -e

BUCKET_NAME="siddhant-portfolio-2025"
AWS_REGION="ap-south-1"
API_STAGE="prod"
API_ENDPOINT_FILE=".tmp_apigw_url.txt"  # Created during API creation

echo "📂 Checking API endpoint file..."
if [ ! -f "$API_ENDPOINT_FILE" ]; then
  echo "❌ Missing $API_ENDPOINT_FILE. Please run create-api.sh first."
  exit 1
fi

API_GATEWAY_URL=$(cat "$API_ENDPOINT_FILE")

echo "🌐 API Gateway URL: $API_GATEWAY_URL"

# === Replace value in config.js ===
CONFIG_JS="frontend/config.js"
echo "💡 Injecting API URL into $CONFIG_JS..."

cat <<EOF > "$CONFIG_JS"
window.API_GATEWAY_URL = "$API_GATEWAY_URL";
EOF

echo "✅ Injected API URL into config.js"

# === Create bucket only if it doesn't exist ===
if ! aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
  echo "🪣 Creating S3 bucket: $BUCKET_NAME..."
  if [[ "$AWS_REGION" == "us-east-1" ]]; then
    aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$AWS_REGION"
  else
    aws s3api create-bucket \
      --bucket "$BUCKET_NAME" \
      --region "$AWS_REGION" \
      --create-bucket-configuration LocationConstraint="$AWS_REGION"
  fi

  echo "🔓 Disabling block public access..."
  aws s3api delete-public-access-block --bucket "$BUCKET_NAME" || echo "Already removed."

  echo "🌐 Enabling static website hosting..."
  aws s3 website "s3://$BUCKET_NAME/" \
    --index-document index.html \
    --error-document error.html

  echo "🔐 Applying public-read policy..."
  aws s3api put-bucket-policy \
    --bucket "$BUCKET_NAME" \
    --policy file://infra/bucket-policy.json
else
  echo "✅ S3 bucket '$BUCKET_NAME' already exists. Skipping creation."
fi

# === Sync frontend files to S3 ===
echo "🚀 Uploading frontend files to S3 (no-cache)..."
aws s3 sync ./frontend "s3://$BUCKET_NAME/" --delete \
  --exact-timestamps \
  --cache-control "no-cache, no-store, must-revalidate"

# === Final output ===
echo "🌍 Website deployed!"
echo "🔗 http://$BUCKET_NAME.s3-website-$AWS_REGION.amazonaws.com"
