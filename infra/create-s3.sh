#!/bin/bash

set -e
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="siddhant-portfolio-${ACCOUNT_ID}"
AWS_REGION="ap-south-1"
API_STAGE="prod"
API_NAME="ContactAPI"
CONFIG_JS="frontend/config.js"

# === Fetch API ID and construct URL dynamically ===
echo "🌐 Fetching API Gateway ID for '$API_NAME'..."
API_ID=$(aws apigateway get-rest-apis \
  --query "items[?name=='$API_NAME'].id" \
  --output text)

if [[ -z "$API_ID" ]]; then
  echo "❌ Error: API '$API_NAME' not found. Please run create-apigateway.sh first."
  exit 1
fi

API_GATEWAY_URL="https://${API_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}/contact"
echo "🔗 API Gateway URL: $API_GATEWAY_URL"

# === Inject URL into config.js ===
echo "🛠️ Injecting API URL into $CONFIG_JS..."
cat <<EOF > "$CONFIG_JS"
window.API_GATEWAY_URL = "$API_GATEWAY_URL";
EOF
echo "✅ API URL injected into $CONFIG_JS"

# === Create S3 bucket if it doesn't exist ===
if ! aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
  echo "🪣 Creating S3 bucket: $BUCKET_NAME..."
  if [[ "$AWS_REGION" == "us-east-1" ]]; then
    aws s3api create-bucket --bucket "$BUCKET_NAME"
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

  echo "🔐 Applying public-read bucket policy dynamically..."
  cat <<EOF > /tmp/bucket-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
    }
  ]
}
EOF

  aws s3api put-bucket-policy \
    --bucket "$BUCKET_NAME" \
    --policy file:///tmp/bucket-policy.json
else
  echo "✅ S3 bucket '$BUCKET_NAME' already exists. Skipping creation."
fi

# === Sync frontend to S3 ===
echo "🚀 Uploading frontend files to S3 (no-cache)..."
aws s3 sync ./frontend "s3://$BUCKET_NAME/" --delete \
  --exact-timestamps \
  --cache-control "no-cache, no-store, must-revalidate"

# === Final Output ===
echo "🌍 Website deployed!"
echo "🔗 http://$BUCKET_NAME.s3-website-$AWS_REGION.amazonaws.com"
