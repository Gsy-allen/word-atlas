# syntax=docker/dockerfile:1

# ---- Stage 1: build the static site ----
# The project is a Vite + React app. `npm run build` runs `tsc -b && vite build`
# and copies everything under public/ (atlas data, illustrations, audio) into dist/.
FROM node:22-slim AS build
WORKDIR /app

# Install dependencies first so this layer is cached across source-only changes.
COPY package.json package-lock.json ./
RUN npm ci

# Copy the rest of the source and build.
# ATLAS_BASE lets you deploy under a sub-path, e.g. ATLAS_BASE=/words/.
COPY . .
ARG ATLAS_BASE=/
ENV ATLAS_BASE=${ATLAS_BASE}
RUN npm run build

# ---- Stage 2: serve the static site with nginx ----
FROM nginx:1.27-alpine AS runtime

# SPA + static-asset serving rules (try_files fallback, cache headers, gzip).
COPY nginx.conf /etc/nginx/conf.d/default.conf

# The built site. Only dist/ is carried over — node_modules and source are dropped.
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80
# nginx:alpine already runs nginx in the foreground as its default CMD.
