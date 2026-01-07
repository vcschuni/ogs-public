FROM docker.io/dpage/pgadmin4:latest

# Set default admin credentials (CHANGE PASSWORD IMMEDIATELY)
ENV PGADMIN_DEFAULT_EMAIL=volker.schunicht@gov.bc.ca
ENV PGADMIN_DEFAULT_PASSWORD=password

# Create a non-root user and group
RUN groupadd -r pgadmin && useradd -r -g pgadmin pgadmin

# Change ownership of /venv so non-root user can execute
RUN chown -R pgadmin:pgadmin /venv

USER pgadmin

# Expose the web port
EXPOSE 80

