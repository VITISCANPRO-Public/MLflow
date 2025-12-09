#!/bin/bash
set -e

echo "[INFO] Export AWS credentials from HuggingFace variables"

export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION}"
export AWS_REGION="${AWS_REGION}"
export AWS_S3_ENDPOINT="https://s3.${AWS_REGION}.amazonaws.com"
export AWS_S3_REGION="${AWS_REGION}"
export S3_BUCKET_NAME="${S3_BUCKET_NAME}"
export PORT=$PORT
export MLFLOW_BACKEND_STORE_URI="$MLFLOW_BACKEND_STORE_URI"
export MLFLOW_ARTIFACT_ROOT="$MLFLOW_ARTIFACT_ROOT"
export MLFLOW_URI="$MLFLOW_URI"

echo "[INFO] AWS_ACCESS_KEY_ID = ${AWS_ACCESS_KEY_ID:0:4}********"
#echo "[INFO] MLFLOW_BACKEND_STORE_URI = ${MLFLOW_BACKEND_STORE_URI}"


if [ "${AWS_CHECK}" == "yes" ]; then
    # uniquement pour HFace
    echo "[INFO] Testing AWS credentials…"
    aws sts get-caller-identity || {
        echo "[ERROR] AWS credentials invalid or not transmitted to container."
        echo "       boto3/MLflow will fail to push artifacts to S3."
        exit 1
    }

    echo "[INFO] AWS credentials OK. Starting MLflow…"

    echo "[INFO] Checking S3 bucket region..."
    aws s3api get-bucket-location --bucket ${S3_BUCKET_NAME}
fi

exec mlflow server \
    --port $PORT \
    --host 0.0.0.0 \
    --backend-store-uri "$MLFLOW_BACKEND_STORE_URI" \
    --default-artifact-root "$MLFLOW_ARTIFACT_ROOT" \
    --gunicorn-opts --timeout=120

#    --allowed-hosts "$MLFLOW_URI" \