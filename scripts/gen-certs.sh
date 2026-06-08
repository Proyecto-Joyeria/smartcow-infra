#!/bin/bash
set -e

# ─────────────────────────────────────────────────────────────────────────────
# SmartCow Tracker — Generador de certificados TLS para Mosquitto
# Genera: CA, certificado servidor y certificado de cliente de prueba.
# Uso: ./scripts/gen-certs.sh
# ─────────────────────────────────────────────────────────────────────────────

GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

ok()  { echo -e "${GREEN}✓${NC} $1"; }
err() { echo -e "${RED}✗ ERROR:${NC} $1" >&2; exit 1; }

CERTS_DIR="docker/mosquitto/certs"

echo -e "\n${BOLD}SmartCow — Generación de certificados TLS${NC}"
echo "──────────────────────────────────────────"

# Verificar que openssl esté disponible
command -v openssl >/dev/null 2>&1 || err "openssl no está instalado"

mkdir -p "$CERTS_DIR"
cd "$CERTS_DIR"

# ─── CA (Autoridad Certificadora) ─────────────────────────────────────────────
echo -e "\n${BOLD}[1/3] Generando CA (RSA-4096, válida 10 años)${NC}"

openssl genrsa -out ca.key 4096 2>/dev/null
ok "ca.key generado"

openssl req -new -x509 -days 3650 -key ca.key -out ca.crt \
  -subj "/C=CO/ST=Cundinamarca/L=Bogota/O=SmartCow/OU=IoT/CN=SmartCow-CA" 2>/dev/null
ok "ca.crt generado (autofirmado)"

# ─── Certificado del servidor Mosquitto ───────────────────────────────────────
echo -e "\n${BOLD}[2/3] Generando certificado del servidor Mosquitto (válido 10 años)${NC}"

openssl genrsa -out server.key 2048 2>/dev/null
ok "server.key generado"

openssl req -new -key server.key -out server.csr \
  -subj "/C=CO/ST=Cundinamarca/L=Bogota/O=SmartCow/OU=Broker/CN=mosquitto" 2>/dev/null
ok "server.csr generado"

openssl x509 -req -days 3650 -in server.csr \
  -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out server.crt 2>/dev/null
ok "server.crt firmado por la CA"

# ─── Certificado de cliente de prueba ─────────────────────────────────────────
echo -e "\n${BOLD}[3/3] Generando certificado de cliente device-test-001 (válido 2 años)${NC}"

DEVICE="device-test-001"

openssl genrsa -out "${DEVICE}.key" 2048 2>/dev/null
ok "${DEVICE}.key generado"

openssl req -new -key "${DEVICE}.key" -out "${DEVICE}.csr" \
  -subj "/C=CO/O=SmartCow/OU=Collar/CN=${DEVICE}" 2>/dev/null
ok "${DEVICE}.csr generado"

openssl x509 -req -days 730 -in "${DEVICE}.csr" \
  -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out "${DEVICE}.crt" 2>/dev/null
ok "${DEVICE}.crt firmado por la CA"

# ─── Limpiar archivos intermedios ─────────────────────────────────────────────
rm -f server.csr "${DEVICE}.csr" ca.srl
ok "Archivos intermedios (.csr, .srl) eliminados"

# ─── Resumen de fechas de expiración ──────────────────────────────────────────
echo -e "\n${BOLD}Fechas de expiración:${NC}"
echo -e "  ca.crt         $(openssl x509 -enddate -noout -in ca.crt | cut -d= -f2)"
echo -e "  server.crt     $(openssl x509 -enddate -noout -in server.crt | cut -d= -f2)"
echo -e "  ${DEVICE}.crt  $(openssl x509 -enddate -noout -in "${DEVICE}.crt" | cut -d= -f2)"

echo -e "\n${GREEN}${BOLD}¡Certificados generados exitosamente en ${CERTS_DIR}/${NC}"
echo -e "${RED}IMPORTANTE: Nunca commitees *.key ni ca.key al repositorio.${NC}\n"
