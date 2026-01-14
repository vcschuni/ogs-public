FROM docker.io/nginx:1.29-alpine

# Create writable directories
RUN mkdir -p /var/cache/nginx /var/run/nginx \
    && chown -R 1001:0 /var/cache/nginx /var/run/nginx /etc/nginx \
    && chmod -R g+rwX /var/cache/nginx /var/run/nginx /etc/nginx

# Copy in config
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
