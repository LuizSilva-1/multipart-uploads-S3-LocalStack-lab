#!/bin/bash

BUCKET_NAME="lab-upload-incompleto"
ARQUIVO="arquivo-real.zip"
OBJETO_S3="upload-finalizado-real.zip"
ENDPOINT="--endpoint-url=http://localhost:4566"
PROFILE="--profile localstack"

# 1. Criar um .zip real com conteúdo
echo "[INFO] Criando arquivo .zip real..."
mkdir -p test-zip
echo "Arquivo 1 de teste" > test-zip/arquivo1.txt
echo "Arquivo 2 de teste" > test-zip/arquivo2.txt
zip -r $ARQUIVO test-zip/ > /dev/null

# 2. Iniciar upload multipart
UPLOAD_ID=$(aws $PROFILE $ENDPOINT s3api create-multipart-upload \
  --bucket "$BUCKET_NAME" \
  --key "$OBJETO_S3" \
  --query UploadId --output text)

echo "[INFO] Upload ID: $UPLOAD_ID"

# 3. Dividir o arquivo em partes de 5MB (tamanho mínimo suportado no S3 para multipart real)
PARTS=()
PART_SIZE=5242880  # 5MB em bytes
FILE_SIZE=$(stat -c %s "$ARQUIVO")
NUM_PARTS=$(( (FILE_SIZE + PART_SIZE - 1) / PART_SIZE ))

for (( i=0; i<$NUM_PARTS; i++ )); do
  OFFSET=$(( i * PART_SIZE ))
  PART_FILE="part-$((i+1)).bin"
  dd if="$ARQUIVO" of="$PART_FILE" bs=1 skip=$OFFSET count=$PART_SIZE iflag=skip_bytes,count_bytes status=none

  ETAG=$(aws $PROFILE $ENDPOINT s3api upload-part \
    --bucket "$BUCKET_NAME" \
    --key "$OBJETO_S3" \
    --part-number $((i+1)) \
    --body "$PART_FILE" \
    --upload-id "$UPLOAD_ID" \
    --query ETag --output text)

  PARTS+=("{\"ETag\": $ETAG, \"PartNumber\": $((i+1))}")
  echo "[INFO] Parte $((i+1)) enviada: $PART_FILE"
done

# 4. Montar JSON de partes
PARTS_JSON=$(printf '%s\n' "${PARTS[@]}" | jq -s '{Parts: .}')

# 5. Finalizar upload
aws $PROFILE $ENDPOINT s3api complete-multipart-upload \
  --bucket "$BUCKET_NAME" \
  --key "$OBJETO_S3" \
  --upload-id "$UPLOAD_ID" \
  --multipart-upload "$PARTS_JSON"

echo "[✅] Upload finalizado com sucesso: $OBJETO_S3"
