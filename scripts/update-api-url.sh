#!/bin/bash

# Script para atualizar a URL da API na documentação
# Uso: ./scripts/update-api-url.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$(dirname "$SCRIPT_DIR")"

# Pegar URL atual do openapi.json
CURRENT_SERVER=$(jq -r '.servers[0].url // "não definido"' "$DOCS_DIR/openapi.json")
CURRENT_PATH_PREFIX=$(jq -r '.paths | keys[0] | split("/")[1:4] | "/" + join("/")' "$DOCS_DIR/openapi.json")

echo "=========================================="
echo "  Atualizar URL da API - pague.dev Docs"
echo "=========================================="
echo ""
echo "Configuração atual:"
echo "  Servidor: $CURRENT_SERVER"
echo "  Prefixo dos paths: $CURRENT_PATH_PREFIX"
echo ""
echo "Exemplo de URL completa: ${CURRENT_SERVER}${CURRENT_PATH_PREFIX}/customers"
echo ""
echo "-------------------------------------------"
echo ""
read -p "Novo servidor (ex: https://api.pague.dev): " NEW_SERVER

if [ -z "$NEW_SERVER" ]; then
  echo "Erro: Servidor não pode ser vazio."
  exit 1
fi

read -p "Novo prefixo dos paths (ex: /v1 ou /api/external/v1): " NEW_PATH_PREFIX

if [ -z "$NEW_PATH_PREFIX" ]; then
  echo "Erro: Prefixo não pode ser vazio."
  exit 1
fi

echo ""
echo "Nova configuração:"
echo "  Servidor: $NEW_SERVER"
echo "  Prefixo dos paths: $NEW_PATH_PREFIX"
echo "  URL completa: ${NEW_SERVER}${NEW_PATH_PREFIX}/customers"
echo ""
read -p "Confirmar? (s/n): " CONFIRM

if [ "$CONFIRM" != "s" ]; then
  echo "Cancelado."
  exit 0
fi

echo ""
echo "Atualizando..."

# 1. Atualizar servidor no openapi.json
echo "  → Atualizando servidor no openapi.json..."
jq --arg url "$NEW_SERVER" '.servers = [{"url": $url}]' "$DOCS_DIR/openapi.json" > "$DOCS_DIR/openapi.tmp.json"
mv "$DOCS_DIR/openapi.tmp.json" "$DOCS_DIR/openapi.json"

# 2. Atualizar paths no openapi.json
echo "  → Atualizando paths no openapi.json..."
jq --arg old "$CURRENT_PATH_PREFIX" --arg new "$NEW_PATH_PREFIX" \
  '.paths = (.paths | to_entries | map(.key = (.key | sub($old; $new))) | from_entries)' \
  "$DOCS_DIR/openapi.json" > "$DOCS_DIR/openapi.tmp.json"
mv "$DOCS_DIR/openapi.tmp.json" "$DOCS_DIR/openapi.json"

# 3. Atualizar openapi nos arquivos MDX
echo "  → Atualizando arquivos MDX..."
find "$DOCS_DIR/api-reference" -name "*.mdx" -exec sed -i '' "s|$CURRENT_PATH_PREFIX|$NEW_PATH_PREFIX|g" {} \;

# 4. Atualizar index.mdx
echo "  → Atualizando index.mdx..."
sed -i '' "s|${CURRENT_SERVER}${CURRENT_PATH_PREFIX}|${NEW_SERVER}${NEW_PATH_PREFIX}|g" "$DOCS_DIR/index.mdx"

echo ""
echo "✓ Concluído!"
echo ""
echo "Verifique as alterações com: git diff"
