# 🏗️ SmartCow Infra

Repositorio de infraestructura de **SmartCow Tracker** — Contiene el Docker Compose para desarrollo local, configuraciones de servicios (Nginx, Mosquitto, PostgreSQL, Redis) y la documentación técnica completa del proyecto.

---

## 📦 Repositorios del Proyecto

| Repositorio | Descripción | Stack |
|-------------|-------------|-------|
| [`smartcow-api`](https://github.com/tu-usuario/smartcow-api) | Backend API REST + WebSockets + IoT | Node.js 20 + Express + Prisma |
| [`smartcow-web`](https://github.com/tu-usuario/smartcow-web) | Frontend SPA | React 19 + Vite + Tailwind |
| [`smartcow-ai`](https://github.com/tu-usuario/smartcow-ai) | Servicio de predicción ML | Python 3.11 + FastAPI + scikit-learn |
| [`smartcow-infra`](https://github.com/tu-usuario/smartcow-infra) | Infraestructura y documentación | Docker Compose + Nginx + Mosquitto |

---

## 📁 Estructura del Repositorio

```
smartcow-infra/
├── docker/
│   ├── nginx/
│   │   └── nginx.conf          # Reverse proxy + SSL termination
│   ├── mosquitto/
│   │   ├── config/
│   │   │   └── mosquitto.conf  # Broker MQTT config
│   │   ├── certs/              # Certificados TLS (ignorados en git)
│   │   ├── data/               # Persistencia del broker
│   │   └── log/                # Logs del broker
│   ├── postgres/
│   │   └── init.sql            # Script de inicialización de BD
│   └── redis/
│       └── redis.conf          # Configuración Redis
├── scripts/
│   ├── gen-certs.sh            # Generar certificados TLS para Mosquitto
│   ├── setup-dev.sh            # Setup completo del entorno de desarrollo
│   └── backup-db.sh            # Script de backup manual de PostgreSQL
├── docs/
│   ├── SmartCow_SRS_v1.0.0.docx
│   ├── SmartCow_SAD_v1.0.0.docx
│   ├── SmartCow_SDD_v1.0.0.docx
│   ├── SmartCow_ADR_v1.0.0.docx
│   ├── SmartCow_IDD_v1.0.0.docx
│   └── SmartCow_DataModel_v1.0.0.docx
├── docker-compose.yml          # Orquestación desarrollo local
├── docker-compose.prod.yml     # Overrides para producción
└── .env.example
```

---

## 🚀 Levantar el Entorno de Desarrollo

### Prerrequisitos

- Docker >= 24
- Docker Compose >= 2.20
- Git

### 1. Clonar este repositorio

```bash
git clone https://github.com/tu-usuario/smartcow-infra.git
cd smartcow-infra
```

### 2. Configurar variables de entorno

```bash
cp .env.example .env
# Editar .env con tus credenciales locales
```

### 3. Levantar todos los servicios

```bash
docker compose up -d
```

Esto levanta:

| Servicio | URL local | Descripción |
|----------|-----------|-------------|
| `smartcow-api` | http://localhost:4000 | Backend API REST |
| `smartcow-web` | http://localhost:5173 | Frontend React |
| `smartcow-ai` | http://localhost:8000 | Servicio de IA |
| `postgres` | localhost:5432 | Base de datos PostgreSQL |
| `redis` | localhost:6379 | Cache y pub/sub |
| `mosquitto` | localhost:1883 / 8883 | Broker MQTT |

### 4. Verificar que todo está corriendo

```bash
docker compose ps
```

### 5. Ver logs en tiempo real

```bash
# Todos los servicios
docker compose logs -f

# Solo la API
docker compose logs -f smartcow-api

# Solo la BD
docker compose logs -f postgres
```

---

## 🔑 Variables de Entorno

```env
# PostgreSQL
POSTGRES_USER=smartcow
POSTGRES_PASSWORD=smartcow_dev_pass
POSTGRES_DB=smartcow_db

# Redis
REDIS_PASSWORD=

# Puertos
API_PORT=4000
WEB_PORT=5173
AI_PORT=8000
MQTT_PORT=1883
MQTTS_PORT=8883

# Entorno
NODE_ENV=development
```

---

## 🛠️ Comandos Útiles

### Docker Compose

```bash
# Levantar todos los servicios
docker compose up -d

# Detener todos los servicios
docker compose down

# Detener y eliminar volúmenes (reset completo)
docker compose down -v

# Reconstruir imágenes
docker compose build

# Reconstruir y levantar
docker compose up -d --build

# Escalar un servicio
docker compose up -d --scale smartcow-api=2
```

### Base de datos

```bash
# Acceder a PostgreSQL
docker compose exec postgres psql -U smartcow -d smartcow_db

# Ejecutar migraciones
docker compose exec smartcow-api npx prisma migrate dev

# Abrir Prisma Studio
docker compose exec smartcow-api npx prisma studio

# Backup manual
./scripts/backup-db.sh
```

### MQTT

```bash
# Publicar un mensaje de prueba (telemetría simulada)
docker compose exec mosquitto mosquitto_pub \
  -h localhost -p 1883 \
  -t "smartcow/farms/test-farm/animals/test-animal/telemetry" \
  -m '{"d":"device-001","ts":1748390400000,"la":4.7109,"lo":-74.0721,"ac":5.0,"sp":0.0,"tp":384,"hr":62,"ax":75,"bt":87,"fv":"1.0.0"}'

# Suscribirse a todos los topics de una finca
docker compose exec mosquitto mosquitto_sub \
  -h localhost -p 1883 \
  -t "smartcow/farms/test-farm/#"
```

### Certificados TLS para Mosquitto

```bash
# Generar CA y certificados del servidor (solo una vez)
./scripts/gen-certs.sh
```

---

## 🏛️ Arquitectura del Sistema

```
                    ┌─────────────────────────────────────┐
                    │           CLIENTE WEB                │
                    │     React SPA (localhost:5173)       │
                    └──────────────┬──────────────────────┘
                                   │ HTTPS + WebSocket
                    ┌──────────────▼──────────────────────┐
                    │           SMARTCOW API               │
                    │    Node.js + Express (port 4000)     │
                    │  Auth │ Animals │ GPS │ Alerts │ WS  │
                    └──┬────────┬────────┬────────┬───────┘
                       │        │        │        │
              ┌────────▼──┐ ┌───▼────┐ ┌▼──────┐ ┌▼─────────────┐
              │ PostgreSQL│ │ Redis  │ │ MQTT  │ │  SmartCow AI  │
              │  port 5432│ │ :6379  │ │ :8883 │ │  port 8000    │
              └───────────┘ └────────┘ └───┬───┘ └──────────────┘
                                           │
                                    ┌──────▼──────┐
                                    │  Collar IoT │
                                    │  ESP32+GPS  │
                                    └─────────────┘
```

---

## 🌍 Entornos

| Entorno | Propósito | Infraestructura |
|---------|-----------|-----------------|
| **Development** | Desarrollo local | Docker Compose local |
| **Staging** | Pruebas de integración y UAT | Railway / Render |
| **Production** | Usuarios reales | Railway o AWS ECS + Supabase + Cloudflare |

---

## 📄 Documentación Técnica

La carpeta `docs/` contiene la documentación técnica completa del proyecto:

| Documento | Descripción |
|-----------|-------------|
| `SRS v1.0.0` | Especificación de Requisitos de Software (IEEE 830 + ISO 25010) |
| `SAD v1.0.0` | Documento de Arquitectura de Software (IEEE 42010 + C4 Model) |
| `SDD v1.0.0` | Documento de Diseño de Software (IEEE 1016 + SOLID + GoF) |
| `ADR v1.0.0` | Architecture Decision Records — 10 decisiones documentadas |
| `IDD v1.0.0` | Documento de Diseño de Interfaces (OpenAPI 3.1 + WCAG 2.1) |
| `Modelo de Datos v1.0.0` | Esquema completo de BD (PostgreSQL 15 + ISO 25012) |

---

## 🤝 Contribución

1. Crea una rama desde `main`: `git checkout -b infra/descripcion`
2. Haz tus cambios en la configuración o documentación
3. Verifica que `docker compose up -d` sigue funcionando correctamente
4. Abre un Pull Request hacia `main`

---

## 📝 Licencia

Proyecto — SmartCow Tracker © 2026
