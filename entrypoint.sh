#!/bin/bash
set -e

# ─── Startup logging ────
# Mask credentials in logs: only show the first 4 characters
echo "[INFO] Starting MLflow server..."
echo "[INFO] AWS_ACCESS_KEY_ID      = ${AWS_ACCESS_KEY_ID:0:4}********"
echo "[INFO] AWS_DEFAULT_REGION     = ${AWS_DEFAULT_REGION}"
echo "[INFO] MLFLOW_ARTIFACT_ROOT   = ${MLFLOW_ARTIFACT_ROOT}"
echo "[INFO] PORT                   = ${PORT}"

# ─── Optional AWS credential check ───
# Set AWS_CHECK=yes to verify credentials before starting the server.
# Useful for debugging. Set to "no" in production to speed up startup.

if [ "${AWS_CHECK}" == "yes" ]; then
    echo "[INFO] Testing AWS credentials..."
    python3 -c "
import boto3, sys
try:
    sts = boto3.client('sts')
    identity = sts.get_caller_identity()
    print(f\"[INFO] AWS credentials OK — Account: {identity['Account']}\")
except Exception as e:
    print(f'[ERROR] AWS credentials invalid: {e}', file=sys.stderr)
    sys.exit(1)

try:
    s3 = boto3.client('s3')
    location = s3.get_bucket_location(Bucket='${S3_BUCKET_NAME}')
    region = location['LocationConstraint'] or 'us-east-1'
    print(f'[INFO] S3 bucket region: {region}')
except Exception as e:
    print(f'[ERROR] Cannot access S3 bucket: {e}', file=sys.stderr)
    sys.exit(1)
"
    echo "[INFO] AWS check complete."
fi

# ─── Start MLflow server ────
# --backend-store-uri  : PostgreSQL connection string (run metadata)
# --default-artifact-root : S3 path (model files, plots, etc.)
# --allowed-hosts      : defaults to "*" if not set (accepts all hosts)
# --cors-allowed-origins : allows the MLflow UI to be loaded from any origin
exec mlflow server \
    --port "${PORT}" \
    --host 0.0.0.0 \
    --backend-store-uri "${MLFLOW_BACKEND_STORE_URI}" \
    --default-artifact-root "${MLFLOW_ARTIFACT_ROOT}" \
    --allowed-hosts "${MLFLOW_ALLOWED_HOSTS:-*}" \
    --cors-allowed-origins "*"
# For the allowed hosts : the syntax -* means that we use the variable 
# if it exists, otherwise we use * as the default value (accept all hosts)