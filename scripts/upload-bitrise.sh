#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <AUTH_TOKEN> <FILE_PATH> <ARTIFACT_UUID>"
  exit 2
fi

AUTH_TOKEN="$1"
FILE_PATH="$2"
ARTIFACT_UUID="$3"

if [ ! -f "$FILE_PATH" ]; then
  echo "File not found: $FILE_PATH" >&2
  exit 1
fi

FILE_NAME=$(basename "$FILE_PATH")
# Try GNU stat then BSD stat
if stat --version >/dev/null 2>&1; then
  FILE_SIZE=$(stat -c%s "$FILE_PATH")
else
  FILE_SIZE=$(stat -f%z "$FILE_PATH")
fi

ENC_FILE_NAME=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$FILE_NAME")
BASE_URL="https://api.bitrise.io/release-management/v1/connected-apps/c0ad8c8f-f85a-4566-b1cf-407b74666ede/installable-artifacts/$ARTIFACT_UUID"
REQUEST1_URL="$BASE_URL/upload-url?file_name=$ENC_FILE_NAME&file_size_bytes=$FILE_SIZE"

echo "Requesting upload URL..."
RESP=$(curl -s -H "Authorization: $AUTH_TOKEN" "$REQUEST1_URL")
UPLOAD_URL=$(echo "$RESP" | jq -r '.upload_url // .uploadURL // .data.upload_url // empty')
if [ -z "$UPLOAD_URL" ]; then
  echo "Failed to parse upload URL. Response:" >&2
  echo "$RESP" >&2
  exit 1
fi

echo "Uploading file..."
curl -X PUT -H "Content-Type: application/octet-stream" -H "X-Goog-Content-Length-Range: 0,$FILE_SIZE" --upload-file "$FILE_PATH" "$UPLOAD_URL"

echo "Checking status..."
STATUS=$(curl -s -H "Authorization: $AUTH_TOKEN" "$BASE_URL/status")
echo "$STATUS" | jq

echo "Done."