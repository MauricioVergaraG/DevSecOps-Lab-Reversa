# --- Stage 1: Build (El Constructor) ---
# CORRECCIÓN 1: Se fija la versión a "18-alpine" para evitar el error de Node.js v25
FROM node:18-alpine as builder

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . ./

ENV NEXT_TELEMETRY_DISABLED=1

RUN npm run build


# --- Stage 2: Production (La App Final) ---
FROM nginx:stable-alpine

# --- CORRECCIÓN DE HARDENING (TRIVY) ---
# Se actualizan los paquetes del S.O. (Alpine) para mitigar las 5 CVEs
# encontradas por Trivy (ej. en 'libxml2').
# Se usa '&&' para hacerlo en una sola capa de Docker y se borra el caché.
RUN apk update && \
    apk upgrade && \
    rm -rf /var/cache/apk/*
# --- FIN DE LA CORRECCIÓN ---

COPY --from=builder /app/out /usr/share/nginx/html

EXPOSE 3991

ENTRYPOINT ["nginx", "-g", "daemon off;"]

