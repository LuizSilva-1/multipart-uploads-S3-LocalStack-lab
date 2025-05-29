#!/bin/bash

echo "[🧹] Limpando arquivos temporários do laboratório..."

# Remover partes de upload
rm -f part-*.bin

# Remover arquivos .zip gerados no teste
rm -f arquivo-grande.zip
rm -f arquivo-real.zip
rm -f upload-finalizado.zip
rm -f upload-finalizado-real.zip

# Remover diretório com arquivos compactados
rm -rf test-zip/

# (Opcional) Parar e remover container localstack
# docker-compose down

echo "[✅] Limpeza concluída. Ambiente pronto para novo teste."
