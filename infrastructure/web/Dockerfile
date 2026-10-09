# Web container: the Flutter web build (built beforehand with
#   flutter build web --release --no-web-resources-cdn --no-wasm-dry-run)
# served by unprivileged nginx on port 8080. Build context: repository root.
ARG NGINX_IMAGE=nginxinc/nginx-unprivileged:1.29-alpine
FROM ${NGINX_IMAGE}
# Alpine security updates (the base image can lag behind fixed packages).
USER root
RUN apk upgrade --no-cache
COPY --chown=nginx:nginx infrastructure/web/nginx.conf /etc/nginx/nginx.conf
COPY --chown=nginx:nginx build/web /usr/share/nginx/html
# Pre-compress once at the highest level (served by gzip_static): smaller
# first load on mobile data and no compression work on the NAS per request.
RUN find /usr/share/nginx/html -type f \
      \( -name '*.js' -o -name '*.mjs' -o -name '*.wasm' -o -name '*.json' -o -name '*.html' \
         -o -name '*.css' -o -name '*.svg' -o -name '*.ttf' -o -name '*.otf' -o -name '*.bin' \) \
      -size +1k -exec gzip -9 -k -n {} \; \
 && chown -R nginx:nginx /usr/share/nginx/html
USER nginx
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1
