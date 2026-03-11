#!/bin/sh
set -e

CONFIG_DIR="$HOME/.openclaw"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"

mkdir -p "$CONFIG_DIR"

# Build allowedOrigins JSON array from comma-separated OPENCLAW_ALLOWED_ORIGINS
ORIGINS_JSON="[]"
if [ -n "$OPENCLAW_ALLOWED_ORIGINS" ]; then
  ORIGINS_JSON=$(echo "$OPENCLAW_ALLOWED_ORIGINS" | awk -F',' '{
    printf "["
    for (i=1; i<=NF; i++) {
      gsub(/^[ \t]+|[ \t]+$/, "", $i)
      if (i > 1) printf ","
      printf "\"%s\"", $i
    }
    printf "]"
  }')
fi

# Determine auth block — token takes precedence over password
AUTH_BLOCK=""
if [ -n "$OPENCLAW_GATEWAY_TOKEN" ]; then
  AUTH_BLOCK="\"auth\": { \"mode\": \"token\", \"token\": \"$OPENCLAW_GATEWAY_TOKEN\" },"
elif [ -n "$OPENCLAW_GATEWAY_PASSWORD" ]; then
  AUTH_BLOCK="\"auth\": { \"mode\": \"password\", \"password\": \"$OPENCLAW_GATEWAY_PASSWORD\" },"
fi

cat > "$CONFIG_FILE" <<EOF
{
  "gateway": {
    "bind": "lan",
    ${AUTH_BLOCK}
    "controlUi": {
      "allowedOrigins": ${ORIGINS_JSON}
    }
  }
}
EOF

echo "Generated $CONFIG_FILE:"
cat "$CONFIG_FILE"

exec node openclaw.mjs gateway --allow-unconfigured
