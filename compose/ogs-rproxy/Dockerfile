FROM docker.io/ubuntu/nginx:1.27-24.04_stable

COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
