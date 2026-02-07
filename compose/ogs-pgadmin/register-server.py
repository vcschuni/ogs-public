#!/usr/bin/env python3
import os
from pgadmin4 import create_app
from pgadmin.model import Server, db

app = create_app()
app.app_context().push()

# Hardcoded PostgreSQL connection info
SERVER_NAME = "ogs-postgresql-cluster"
HOST = "ogs-postgresql-cluster-primary"
PORT = 5432
USERNAME = "postgres"

# Password from environment variable
PASSWORD = os.environ.get("POSTGRES_PASSWORD")

if not PASSWORD:
    raise ValueError("Environment variable POSTGRES_PASSWORD is not set!")

# Check if server already exists
existing = Server.query.filter_by(name=SERVER_NAME).first()
if not existing:
    srv = Server(
        name=SERVER_NAME,
        host=HOST,
        port=PORT,
        username=USERNAME,
        ssl_mode="prefer"
    )
    srv.password = PASSWORD
    db.session.add(srv)
    db.session.commit()
    print(f"Server '{SERVER_NAME}' added successfully!")
else:
    print(f"Server '{SERVER_NAME}' already exists.")
