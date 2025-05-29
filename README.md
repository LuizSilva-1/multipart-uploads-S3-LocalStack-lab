
# 🧪 Prova de Conceito: Upload Multipart no S3 usando LocalStack

Este projeto demonstra uma Prova de Conceito (PoC) para validar o comportamento de uploads incompletos e completos no Amazon S3, utilizando o **LocalStack** para simulação local, sem custos e sem afetar a conta AWS real.

---

## 🎯 Objetivo

Validar como uploads multipart funcionam:

- O que acontece quando um upload é **interrompido**
- Como identificar uploads **incompletos**
- Como fazer um upload **completo e válido**
- Como visualizar o conteúdo real de um arquivo `.zip` enviado

---

## 🛠️ Pré-requisitos

- Docker e Docker Compose
- AWS CLI instalado
- `jq` instalado (`sudo apt install jq -y`)
- `zip` instalado (`sudo apt install zip -y`)

---

## 🧱 Etapa 1 – Subir o ambiente LocalStack

### Criar o `docker-compose.yml`:

```yaml
version: '3.8'

services:
  localstack:
    image: localstack/localstack:latest
    container_name: localstack
    ports:
      - "4566:4566"
    environment:
      - SERVICES=s3
      - DEBUG=1
    volumes:
      - "./localstack:/var/lib/localstack"
      - "/var/run/docker.sock:/var/run/docker.sock"
```

### Subir o ambiente:

```bash
docker-compose up -d
```

Verifique se está rodando:

```bash
curl http://localhost:4566/_localstack/health
```

---

## ⚙️ Etapa 2 – Configurar o perfil AWS local

Crie um perfil `localstack` com credenciais fictícias:

```bash
aws configure --profile localstack
```

Valores recomendados:

```
AWS Access Key ID: test
AWS Secret Access Key: test
Default region name: us-east-1
Default output format: json
```

---

## 📂 Etapa 3 – Criar o bucket no LocalStack

```bash
aws --profile localstack --endpoint-url=http://localhost:4566 s3 mb s3://lab-upload-incompleto
```

---

## 🧪 Etapa 4 – Simular upload incompleto (falho)

Execute o script `upload_parcial.sh`. Ele faz apenas a **primeira parte** de um upload multipart.

```bash
chmod +x upload_parcial.sh
./upload_parcial.sh
```

Depois, veja que o arquivo **não aparece na listagem**:

```bash
aws --profile localstack --endpoint-url=http://localhost:4566 s3 ls s3://lab-upload-incompleto
```

E veja o upload pendente:

```bash
aws --profile localstack --endpoint-url=http://localhost:4566 s3api list-multipart-uploads --bucket lab-upload-incompleto --output table
```

---

## 📦 Etapa 5 – Fazer upload multipart completo de um arquivo real

Execute o script `upload_completo.sh`:

```bash
chmod +x upload_completo.sh
./upload_completo.sh
```

O script:
- Cria um `.zip` real
- Divide em partes
- Faz o upload de cada parte
- Finaliza corretamente o upload

---

## 📥 Etapa 6 – Baixar e inspecionar o arquivo completo

```bash
aws --profile localstack --endpoint-url=http://localhost:4566 s3 cp s3://lab-upload-incompleto/upload-finalizado-real.zip .
unzip -l upload-finalizado-real.zip
```

Você verá os arquivos reais compactados e enviados.

---

## 🧪 Etapa 7 – Simular política da AWS para apagar apenas uploads incompletos

Como o LocalStack não executa automaticamente políticas de ciclo de vida (Lifecycle Policies), vamos **simular manualmente** o que a política real da AWS faria após X dias.

### 📋 Comportamento esperado na AWS real

```json
{
  "Rules": [
    {
      "ID": "AbortMultipartUploads",
      "Status": "Enabled",
      "Prefix": "",
      "AbortIncompleteMultipartUpload": {
        "DaysAfterInitiation": 1
      }
    }
  ]
}
```

Essa política remove **somente uploads incompletos** após 1 dia. Arquivos finalizados não são afetados.

### ✅ Simulação manual via CLI (equivalente ao efeito da política)

```bash
aws --profile localstack --endpoint-url=http://localhost:4566 s3api list-multipart-uploads   --bucket lab-upload-incompleto   --query "Uploads[].{Key:Key,UploadId:UploadId}"   --output text |
while read key upload_id; do
  echo "Abortando: $key ($upload_id)"
  aws --profile localstack --endpoint-url=http://localhost:4566 s3api abort-multipart-upload     --bucket lab-upload-incompleto     --key "$key"     --upload-id "$upload_id"
done
```

### 🔍 Validação

1. Verifique que **nenhum upload incompleto resta**:

```bash
aws --profile localstack --endpoint-url=http://localhost:4566 s3api list-multipart-uploads --bucket lab-upload-incompleto
```

2. Verifique que o **objeto válido permanece no bucket**:

```bash
aws --profile localstack --endpoint-url=http://localhost:4566 s3 ls s3://lab-upload-incompleto
```

✅ Se o arquivo válido ainda estiver lá, a simulação está concluída com sucesso: **a política afeta apenas uploads incompletos.**

---

## ✅ Conclusão

- Uploads incompletos **não aparecem** na listagem do bucket
- Eles **ocupam espaço invisível** no S3 real (mas visível via `list-multipart-uploads`)
- O processo de upload multipart foi simulado com sucesso localmente usando o LocalStack

---

## 🔁 Etapa 8 – Reiniciar o laboratório do zero

Para reiniciar todo o ambiente e executar o laboratório novamente sem resíduos de testes anteriores:

### 🧹 1. Limpar arquivos locais

```bash
./limpar_lab.sh
```

Esse script remove arquivos `.bin`, `.zip`, pastas temporárias e resultados locais.

### 🔄 2. Parar e limpar o estado do LocalStack

```bash
docker-compose down -v
```

Isso remove volumes e dados persistentes do LocalStack.

### 🚀 3. Subir um ambiente novo e limpo

```bash
docker-compose up -d
```

---

## 📘 Arquivos principais

- `upload_parcial.sh`: faz upload incompleto
- `upload_completo.sh`: faz upload completo de um `.zip` real
- `docker-compose.yml`: sobe o LocalStack
