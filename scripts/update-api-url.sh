#!/bin/bash

# Script para atualizar a URL da API na documentação
# Uso: ./scripts/update-api-url.sh
#
# Exemplos:
#   Produção:    https://api.pague.dev + /v1
#   Desenvolvimento: http://localhost:4000 + /api/external/v1

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$(dirname "$SCRIPT_DIR")"

# Pegar configuração atual
CURRENT_SERVER=$(jq -r '.servers[0].url // "não definido"' "$DOCS_DIR/openapi.json")
CURRENT_PATH=$(jq -r '.paths | keys[0] | split("/") | .[1:-1] | "/" + join("/")' "$DOCS_DIR/openapi.json")
CURRENT_INDEX_URL=$(grep -E "^https?://" "$DOCS_DIR/index.mdx" 2>/dev/null | head -1 | xargs || echo "")

echo "=========================================="
echo "  Atualizar URL da API - pague.dev Docs"
echo "=========================================="
echo ""
echo "Configuração atual:"
echo "  Servidor: $CURRENT_SERVER"
echo "  Path: $CURRENT_PATH"
echo "  URL completa: ${CURRENT_SERVER}${CURRENT_PATH}"
echo ""
echo "-------------------------------------------"
echo ""
read -p "Novo servidor (ex: https://api.pague.dev): " NEW_SERVER

if [ -z "$NEW_SERVER" ]; then
  echo "Erro: Servidor não pode ser vazio."
  exit 1
fi

# Remover trailing slash
NEW_SERVER="${NEW_SERVER%/}"

read -p "Novo path (ex: /v1 ou /api/external/v1): " NEW_PATH

if [ -z "$NEW_PATH" ]; then
  echo "Erro: Path não pode ser vazio."
  exit 1
fi

# Garantir que começa com /
[[ "$NEW_PATH" != /* ]] && NEW_PATH="/$NEW_PATH"
# Remover trailing slash
NEW_PATH="${NEW_PATH%/}"

NEW_FULL_URL="${NEW_SERVER}${NEW_PATH}"

echo ""
echo "Nova configuração:"
echo "  Servidor: $NEW_SERVER"
echo "  Path: $NEW_PATH"
echo "  URL completa: $NEW_FULL_URL"
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
jq --arg old "$CURRENT_PATH" --arg new "$NEW_PATH" '
  .paths = (.paths | to_entries | map(
    .key = (.key | sub("^\($old)"; $new))
  ) | from_entries)
' "$DOCS_DIR/openapi.json" > "$DOCS_DIR/openapi.tmp.json"
mv "$DOCS_DIR/openapi.tmp.json" "$DOCS_DIR/openapi.json"

# 3. Atualizar arquivos MDX
echo "  → Atualizando arquivos MDX..."
find "$DOCS_DIR/api-reference" -name "*.mdx" -exec sed -i '' "s|$CURRENT_PATH/|$NEW_PATH/|g" {} \;

# 4. Atualizar index.mdx
echo "  → Atualizando index.mdx..."
if [ -n "$CURRENT_INDEX_URL" ]; then
  sed -i '' "s|$CURRENT_INDEX_URL|$NEW_FULL_URL|g" "$DOCS_DIR/index.mdx"
fi

echo ""
echo "✓ Concluído!"
echo ""
echo "URL base: $NEW_FULL_URL"
echo ""
echo "Verifique:"
echo "  - openapi.json paths: $(jq -r '.paths | keys[0]' "$DOCS_DIR/openapi.json")"
echo "  - index.mdx URL: $(grep -E "^https?://" "$DOCS_DIR/index.mdx" | head -1)"
echo ""
echo "git diff para ver alterações"
