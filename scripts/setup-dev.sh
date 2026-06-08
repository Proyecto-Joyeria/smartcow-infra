#!/bin/bash
set -e

# ─────────────────────────────────────────────────────────────────────────────
# SmartCow Tracker — Setup inicial para desarrollador nuevo
# Uso: ./scripts/setup-dev.sh
# ─────────────────────────────────────────────────────────────────────────────

GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

ok()  { echo -e "${GREEN}✓${NC} $1"; }
err() { echo -e "${RED}✗ ERROR:${NC} $1" >&2; exit 1; }
info(){ echo -e "  $1"; }

echo -e "\n${BOLD}SmartCow — Setup del entorno de desarrollo${NC}"
echo "─────────────────────────────────────────────"

# ─── Verificar dependencias ────────────────────────────────────────────────────
echo -e "\n${BOLD}[1/4] Verificando dependencias${NC}"

command -v docker >/dev/null 2>&1 || err "Docker no está instalado. Instalar desde https://docs.docker.com/get-docker/"
DOCKER_VERSION=$(docker --version | grep -oP '\d+\.\d+' | head -1)
ok "Docker ${DOCKER_VERSION} encontrado"

docker compose version >/dev/null 2>&1 || err "Docker Compose v2 no está disponible. Actualizar Docker Desktop o instalar el plugin."
COMPOSE_VERSION=$(docker compose version --short)
ok "Docker Compose ${COMPOSE_VERSION} encontrado"

# ─── Configurar variables de entorno ──────────────────────────────────────────
echo -e "\n${BOLD}[2/4] Configurando variables de entorno${NC}"

if [ ! -f ".env" ]; then
  cp .env.example .env
  ok ".env creado desde .env.example"
  info "Revisa .env y ajusta los valores si es necesario"
else
  ok ".env ya existe, no se sobreescribe"
fi

# ─── Crear carpetas necesarias ─────────────────────────────────────────────────
echo -e "\n${BOLD}[3/4] Creando carpetas necesarias${NC}"

mkdir -p docker/mosquitto/data
mkdir -p docker/mosquitto/log
mkdir -p docker/mosquitto/certs
ok "Carpetas de Mosquitto listas"

# ─── Levantar servicios de infraestructura ────────────────────────────────────
echo -e "\n${BOLD}[4/4] Levantando postgres y redis${NC}"

docker compose up -d postgres redis
ok "Contenedores iniciados"

# Esperar a que los healthchecks pasen
echo "  Esperando healthchecks..."
RETRIES=30
until [ "$(docker compose ps postgres --format json | grep -o '"Health":"healthy"')" ] && \
      [ "$(docker compose ps redis --format json | grep -o '"Health":"healthy"')" ]; do
  RETRIES=$((RETRIES - 1))
  [ $RETRIES -le 0 ] && err "Los servicios no pasaron el healthcheck a tiempo. Revisa: docker compose logs"
  sleep 2
done

ok "postgres está healthy"
ok "redis está healthy"

# ─── Resumen ──────────────────────────────────────────────────────────────────
echo -e "\n${GREEN}${BOLD}¡Setup completado!${NC}"
echo -e "\n  Servicios disponibles:"
echo -e "  ${BOLD}PostgreSQL${NC}  → localhost:5432"
echo -e "  ${BOLD}Redis${NC}       → localhost:6379"
echo -e "  ${BOLD}Mosquitto${NC}   → localhost:1883 (MQTT) / localhost:8883 (MQTTS)"
echo -e "\n  Próximos pasos:"
echo -e "  1. Generar certificados TLS:  ${BOLD}./scripts/gen-certs.sh${NC}"
echo -e "  2. Levantar Mosquitto:        ${BOLD}docker compose up -d mosquitto${NC}"
echo -e "  3. Ver logs:                  ${BOLD}docker compose logs -f${NC}\n"
