#!/bin/bash

# Script para atualizar a URL base da API na documentação
# Uso: ./scripts/update-api-url.sh
#
# Exemplos:
#   Produção:    https://api.pague.dev/v1
#   Desenvolvimento: http://localhost:4000/api/external/v1
#   Ngrok: https://xxx.ngrok-free.app/api/external/v1

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$(dirname "$SCRIPT_DIR")"

# Pegar configuração atual
CURRENT_SERVER=$(jq -r '.servers[0].url // "não definido"' "$DOCS_DIR/openapi.json")

echo "=========================================="
echo "  Atualizar URL da API - pague.dev Docs"
echo "=========================================="
echo ""
echo "Configuração atual:"
echo "  URL base: $CURRENT_SERVER"
echo ""
echo "-------------------------------------------"
echo ""
read -p "Nova URL base (ex: https://api.pague.dev/v1): " NEW_SERVER

if [ -z "$NEW_SERVER" ]; then
  echo "Erro: URL não pode ser vazia."
  exit 1
fi

# Remover trailing slash
NEW_SERVER="${NEW_SERVER%/}"

echo ""
echo "Nova configuração:"
echo "  URL base: $NEW_SERVER"
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

# 2. Atualizar index.mdx (se houver URL antiga)
echo "  → Atualizando index.mdx..."
if [ -n "$CURRENT_SERVER" ] && [ "$CURRENT_SERVER" != "não definido" ]; then
  sed -i '' "s|$CURRENT_SERVER|$NEW_SERVER|g" "$DOCS_DIR/index.mdx" 2>/dev/null || true
fi

echo ""
echo "✓ Concluído!"
echo ""
echo "URL base: $NEW_SERVER"
echo ""
echo "Nota: Os paths da API são relativos (/pix, /customers, etc.)"
echo "      O servidor já inclui o prefixo completo."
echo ""
echo "git diff para ver alterações"
