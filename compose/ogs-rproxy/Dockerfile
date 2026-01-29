#FROM nginx:1.22-ubi9
FROM docker.io/nginx:1.29

COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
