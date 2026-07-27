# ==============================================================================
# Multi-stage Dockerfile para inventario-app
# Stage 1: Build & Test (Fail-Fast execution)
# Stage 2: Production Minimal Runtime Image
# ==============================================================================

# ------------------------------------------------------------------------------
# Stage 1: Build and Unit Testing
# ------------------------------------------------------------------------------
FROM node:alpine AS builder

WORKDIR /app

# Copiar manifiestos de dependencias
COPY package*.json ./

# Instalar dependencias completas para compilación y pruebas
RUN npm ci

# Copiar código fuente del proyecto
COPY . .

# Ejecución estricta de pruebas unitarias. Si alguna falla, la imagen NO se construye.
RUN npm test

# ------------------------------------------------------------------------------
# Stage 2: Production Image
# ------------------------------------------------------------------------------
FROM node:alpine AS production

WORKDIR /app

# Configuración de variables de entorno por defecto para producción
ENV NODE_ENV=production \
    PORT=3000

# Copiar manifiestos e instalar ÚNICAMENTE dependencias de producción
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Copiar únicamente los componentes necesarios desde el Stage 1
COPY --from=builder /app/server.js ./
COPY --from=builder /app/db.js ./
COPY --from=builder /app/public ./public
COPY --from=builder /app/data ./data

# Exponer el puerto del contenedor
EXPOSE 3000

# Definir el comando de arranque
CMD ["npm", "start"]
