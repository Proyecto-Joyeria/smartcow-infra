-- ─────────────────────────────────────────────────────────────────────────────
-- SmartCow Tracker — Inicialización de PostgreSQL
-- Este script se ejecuta UNA SOLA VEZ al crear el contenedor por primera vez.
-- Las migraciones del esquema (tablas, índices, relaciones) las gestiona Prisma
-- desde smartcow-api. Este script solo habilita extensiones necesarias.
-- ─────────────────────────────────────────────────────────────────────────────

-- Cifrado y hashing (usado por Prisma para campos encriptados)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Generación de UUIDs v4 (usado como PK en todos los modelos)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
