#FROM nginx:1.22-ubi9
FROM docker.io/nginx:1.29

COPY nginx.conf /etc/nginx/nginx.conf

# Make cache/temp dirs writable for any UID
RUN mkdir -p /var/cache/nginx/client_temp /var/run/nginx \
    && chmod -R 777 /var/cache/nginx /var/run/nginx

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
