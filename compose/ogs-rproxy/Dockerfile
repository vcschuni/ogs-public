FROM nginx:1.28.1

# Copy custom config
COPY nginx.conf /etc/nginx/nginx.conf

# Create writable temp directories under /tmp
RUN mkdir -p /tmp/nginx/cache /tmp/nginx/run \
    && chmod -R 0777 /tmp/nginx

# Tell Nginx to use them for temp/cache
ENV NGINX_TMPDIR=/tmp/nginx
ENV NGINX_CACHE=/tmp/nginx/cache
ENV NGINX_RUN=/tmp/nginx/run

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
