Yes — your current script **does have the same CORS issue**.

---

### ❌ Problem Recap

Your script sets up:

✅ `POST` method
✅ Lambda integration for POST
✅ OPTIONS method + CORS headers
❌ **But it's missing this critical part**:

> ❌ **No CORS headers on the POST method response.**

That’s exactly why your browser fetch gets blocked even though `curl` works — because the browser checks CORS headers in **actual POST response** too.

---

### ✅ What You Need to Add

To fix it, add this block **after the POST integration** section and before OPTIONS:

```bash
# === CORS for POST ===
echo "🛠️ Adding CORS headers to POST method response..."
aws apigateway put-method-response \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method POST \
  --status-code 200 \
  --response-parameters "method.response.header.Access-Control-Allow-Origin=true" \
  --region $REGION || echo "⚠️ POST method response may already exist."

aws apigateway put-integration-response \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method POST \
  --status-code 200 \
  --response-parameters "method.response.header.Access-Control-Allow-Origin='*'" \
  --region $REGION || echo "⚠️ POST integration response may already exist."
```

---

### 🧩 Full Integration Position in Your Script

Paste that right **after this block in your script**:

```bash
echo "🔌 Setting POST integration with Lambda..."
aws apigateway put-integration ...
```

---

### ✅ Updated Flow Order

1. Setup POST method
2. Integrate POST with Lambda
3. ✅ **Add POST method CORS response headers ← (was missing)**
4. Setup OPTIONS method
5. Deploy

---

### 🔄 Let Me Know

If you want, I’ll **edit and paste your full updated script** here with the fix built in — just say the word.
