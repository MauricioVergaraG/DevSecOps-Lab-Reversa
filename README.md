# **PROYECTO "HAT.SH REFORGED"**

## **Introducción**

Este proyecto documenta el proceso de ingeniería inversa, hardening de seguridad (DevSecOps) y personalización de la aplicación web de código abierto hat.sh (<https://github.com/sh-dv/hat.sh>).

El objetivo fue tomar la aplicación original, realizar un análisis de vulnerabilidades FOSS, mitigar los riesgos encontrados a nivel de código (SAST) y de imagen (SCA), personalizar el branding y desplegar una nueva imagen Docker pública, reforzada y lista para su consumo.

## **1\. Ingeniería Inversa y Análisis de la Aplicación Original**

Se realizó un análisis exhaustivo de la estructura de hat.sh para comprender su funcionamiento, dependencias y dónde se encontraban los elementos a modificar.

- **Tecnologías Identificadas:**
  - **Frontend:** Next.js v12 (React)
  - **Backend:** Nginx (servido estático desde un contenedor Docker)
  - **Dependencias Clave:** libsodium-wrappers (criptografía en el navegador), @material-ui (componentes de UI).
- **Estructura del Proyecto:**
  - src/: Contiene el código fuente de los componentes de React.
  - public/: Contiene todos los activos estáticos (imágenes, logos, iconos).
  - package.json: Define las dependencias y los scripts de build.
  - Dockerfile: Define el proceso de construcción de la imagen.
- **Localización de Branding:**
  - **Logos:**
    - public/assets/images/logo.png (Reemplazado por public/assets2/images/logo.png)
    - public/assets/images/logo2.png (Reemplazado por public/assets2/images/logo2.png)
    - /assets2/images/logo.jpeg" alt="logo" width="60" (Tamaños modificados "/assets2/images/logo2.jpeg" alt="logo" width="140" height="auto")
  - **Rutas de código modificadas (Logos):**
    - src/components/Footer.js | src: /assets/icons/\${res.alt}-logo.png (Reemplazado por src: /assets2/icons/\${res.alt}-logo.png)
  - **Leyendas:**
    - src/components/Footer.js - "Built and developed by sh-dv" (Reemplazado por Modificado por Mauricio)
    - src/components/Footer.js - "Donations" (Reemplazado por Laboratorio Docker Uniminuto)
    - locales/index.js - "Cifrado de archivos del lado del cliente sencillo…." (Reemplazado por App modificada para Laboratorio Uniminuto...)
  - **Imagen "Donation accept":**
    - public/assets/icons/qr-logo.png (Reemplazado por public/assets2/icons/qr-logo.png)

## **2\. Análisis de Vulnerabilidades con DockerScout y Herramientas FOSS**

Se utilizó un conjunto de herramientas FOSS para escanear la aplicación original, complementado con DockerScout.

### **Hallazgo 1: Falla de Compilación del Dockerfile Original**

El primer paso fue consumir el Dockerfile provisto por el desarrollador. Este intento falló inmediatamente.

- **Causa:** El Dockerfile original usaba FROM node:alpine. Esta es una etiqueta "flotante" que descargó la versión más reciente de Node.js (v25+), la cual es incompatible con las dependencias antiguas del proyecto.
- **Error:** TypeError: Cannot read properties of undefined (reading 'prototype').
- **Mitigación Inicial:** El Dockerfile tuvo que ser modificado para fijar una versión compatible (FROM node:18-alpine) antes de que cualquier análisis pudiera comenzar.

### **Hallazgo 2: Análisis de Dependencias de Código (npm audit)**

- **Hallazgo:** Se reportaron **18 vulnerabilidades** en las dependencias de Node.js.
- **Severidad:** 5 CRÍTICAS, 5 ALTAS, 7 Moderadas, 1 Baja.

### **Hallazgo 3: Análisis de Prácticas del Dockerfile (hadolint)**

- **Hallazgo:** hadolint reportó advertencias sobre el uso de etiquetas flotantes (FROM node:alpine) y formato de ENV (Legacy), validando el "Hallazgo 1".

### **Hallazgo 4: Análisis de Vulnerabilidades de Imagen (Trivy)**

Se escaneó la imagen original (construida con node:18-alpine).

**Comando de Escaneo:**

\# Paso 1: Construir la imagen original (con la corrección de Node.js)  
docker build -t hat-sh-dockerfile .  
<br/>\# Paso 2: Escanear la imagen construida  
trivy image hat-sh-dockerfile:latest  

- **Hallazgo:** Se reportaron **5ulnerabilidades** en la imagen final de Nginx.
- **Severidad:** 2 CRÍTICAS (CVE-2025-49794, CVE-2025-49796) y 2 ALTAS (CVE-2025-49795, CVE-2025-6021).
- **Causa Raíz:** Todas las vulnerabilidades se encontraban en la librería libxml2 y tenían un Status: fixed (arreglable).

### **Hallazgo 5: Análisis Complementario (DockerScout)**

- **Hallazgo:** Como análisis complementario, DockerScout (usando su propia base de datos) reportó 4 vulnerabilidades adicionales de severidad Media y Baja (ej. CVE-2025-48174, CVE-2025-48175) que no fueron marcadas como "Fixable" (Arreglables) por las herramientas FOSS.

## **3\. Corrección de Vulnerabilidades (Hardening)**

Se aplicaron las siguientes mitigaciones para crear una imagen final segura:

- **Mitigación de Código (npm):**
  - **Acción:** Se ejecutó npm audit fix.
  - **Resultado:** Se mitigaron **16 de las 18** vulnerabilidades, eliminando **todas las 5 CRÍTICAS**.
- **Mitigación de Imagen (Dockerfile - Trivy):**
  - **Acción:** Se añadió el comando RUN apk update && apk upgrade && rm -rf /var/cache/apk/\* a la etapa final del Dockerfile (la de nginx).
  - **Resultado:** El re-escaneo con trivy confirmó **0 vulnerabilidades** en la imagen final.
- **Mitigación de Prácticas (Dockerfile - Hadolint):**
  - **Acción:** Se corrigió el Dockerfile (fijando node:18-alpine y ENV NEXT_TELEMETRY_DISABLED=1).
  - **Resultado:** hadolint Dockerfile no reportó **ninguna advertencia**.

## **4\. Personalización del Branding (Fase 4)**

Se utilizó un contenedor de desarrollo (con docker run -v ... node:18-alpine npm run dev) para modificar y verificar los cambios de branding en vivo.

- **Logos:** Se crearon los archivos logo.png, logo2.png y qr-logo.png en la carpeta public/assets2 con activos personalizados.
- **Texto:** Se modificaron las leyendas en src/components/Footer.js y locales/index.js para reflejar la nueva autoría.

## **5\. Recompilación y Despliegue (Fase 5 y 6)**

- **Imagen Final:** Se construyó la imagen final, mauriciovergara/hat-sh-laboratoriouniminuto:latest, usando el Dockerfile endurecido. Esta imagen ahora contiene las mitigaciones de seguridad Y las personalizaciones de branding.
- **Despliegue:** La imagen fue subida (push) exitosamente a Docker Hub.

## **6\. Despliegue en Docker Hub**

La nueva imagen Docker mauriciovergara/hat-sh-laboratoriouniminuto:latest está disponible públicamente en Docker Hub.

- **URL de la Imagen:** <https://hub.docker.com/r/mauriciovergara/hat-sh-laboratoriouniminuto>

### **Pasos para Consumir la Imagen:**

- **Descargar la Imagen:**  
    docker pull mauriciovergara/hat-sh-laboratoriouniminuto:latest  

- **Ejecutar la Aplicación en un Contenedor:**  
    docker run -d -p 8080:80 --name hat-sh-reforged-app mauriciovergara/hat-sh-laboratoriouniminuto:latest  
    <br/>(La aplicación estará disponible en <http://localhost:8080>)

## **7\. Conclusiones**

Este proyecto demostró con éxito el ciclo completo de DevSecOps: tomar una aplicación de código abierto, identificar sus debilidades (tanto en el código como en la infraestructura) a través de un análisis de seguridad, y aplicar mitigaciones correctas para remediar el 100% de las vulnerabilidades críticas.

El resultado es un artefacto final (imagen Docker) que no solo está personalizado, sino que también es verificablemente más seguro que el original, listo para un despliegue confiable en producción.