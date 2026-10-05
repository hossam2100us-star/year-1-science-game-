# syntax=docker/dockerfile:1.7
# Web container: the Flutter web build (built beforehand with
#   flutter build web --release --no-web-resources-cdn --no-wasm-dry-run)
# served by unprivileged nginx on port 8080. Build context: repository root.
FROM nginxinc/nginx-unprivileged:1.29-alpine
COPY --chown=nginx:nginx infrastructure/web/nginx.conf /etc/nginx/nginx.conf
COPY --chown=nginx:nginx build/web /usr/share/nginx/html
USER nginx
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1
