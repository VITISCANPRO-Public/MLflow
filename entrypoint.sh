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
    aws sts get-caller-identity || {
        echo "[ERROR] AWS credentials invalid or not transmitted to container."
        echo "        boto3/MLflow will fail to push artifacts to S3."
        exit 1
    }
    echo "[INFO] AWS credentials OK."

    echo "[INFO] Checking S3 bucket region..."
    aws s3api get-bucket-location --bucket "${S3_BUCKET_NAME}"
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