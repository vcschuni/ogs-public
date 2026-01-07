FROM docker.io/dpage/pgadmin4:latest

# Set default admin credentials (CHANGE PASSWORD IMMEDIATELY)
ENV PGADMIN_DEFAULT_EMAIL=volker.schunicht@gov.bc.ca
ENV PGADMIN_DEFAULT_PASSWORD=password

# This is used to serve pgadmin-web via a subpath (for purpose of reverse proxying)
ENV SCRIPT_NAME=/pgadmin

# Expose the web port
EXPOSE 80
