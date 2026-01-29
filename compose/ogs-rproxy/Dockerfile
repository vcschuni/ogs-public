#FROM registry.access.redhat.com/ubi9/nginx-124
FROM quay.io/redhat/ubi9-nginx-124

COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
