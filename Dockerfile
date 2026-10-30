# Genera db-output.sql desde schema/ (no confía en una copia commiteada, que podría estar
# desactualizada) y lo deja en docker-entrypoint-initdb.d — Postgres lo ejecuta solo, una
# vez, la primera vez que el contenedor arranca con un volumen de datos vacío. db-output.sql
# ya viene "aplanado" (sin \i relativos) por scripts/build.ts, así que no importa el cwd del
# entrypoint al ejecutarlo.

FROM node:22-alpine@sha256:0a7108bf6c7bf5de370ffb1a3ed6be93d405b43ff159f681a8d18c0e2bc2e402 AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM postgres:18-alpine@sha256:77f585114c32fbca283dc835b0596f4e52b51b4c6662d7810b2f4084f60a1873
COPY --from=build /app/db-output.sql /docker-entrypoint-initdb.d/01-schema.sql
