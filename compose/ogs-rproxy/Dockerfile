# Use official HAProxy image
FROM haproxy:2.8-alpine

# Copy HAProxy configuration into the container
COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg

# Expose HTTP port
EXPOSE 8080

# Start HAProxy in foreground
CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg", "-db"]
