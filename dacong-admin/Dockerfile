# ── Stage 1: Build ────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:3.27.1 AS build

WORKDIR /app

# Copy dependency files first for better caching
COPY pubspec.yaml pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy source code
COPY . .

# Build web application
RUN flutter build web \
  --release \
  --web-renderer canvaskit \
  --no-tree-shake-icons

# ── Stage 2: Production ────────────────────────────
FROM nginx:1.27-alpine AS production

# Copy built web app
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Create nginx cache directories
RUN mkdir -p /var/cache/nginx/client_temp \
  && chown -R nginx:nginx /var/cache/nginx \
  && chown -R nginx:nginx /usr/share/nginx/html

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/health || exit 1

# Run nginx
CMD ["nginx", "-g", "daemon off;"]
