#!/bin/bash

BUCKET_NAME="lab-upload-incompleto"
ARQUIVO="arquivo-grande.zip"
OBJETO_S3="teste-upload.zip"
ENDPOINT="--endpoint-url=http://localhost:4566"
PROFILE="--profile localstack"

# Criar arquivo grande (simulando arquivo real)
if [ ! -f "$ARQUIVO" ]; then
  echo "[INFO] Gerando arquivo de 20MB..."
  dd if=/dev/zero of=$ARQUIVO bs=10M count=2
fi

# Iniciar upload multipart
UPLOAD_ID=$(aws $PROFILE $ENDPOINT s3api create-multipart-upload \
  --bucket "$BUCKET_NAME" \
  --key "$OBJETO_S3" \
  --query UploadId --output text)

echo "[INFO] Upload ID: $UPLOAD_ID"

# Enviar apenas a primeira parte (simulando falha/interrupção)
aws $PROFILE $ENDPOINT s3api upload-part \
  --bucket "$BUCKET_NAME" \
  --key "$OBJETO_S3" \
  --part-number 1 \
  --body "$ARQUIVO" \
  --upload-id "$UPLOAD_ID"

# Verificar uploads pendentes
echo "[INFO] Uploads pendentes no bucket:"
aws $PROFILE $ENDPOINT s3api list-multipart-uploads \
  --bucket "$BUCKET_NAME" \
  --output table
