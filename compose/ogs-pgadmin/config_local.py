import os

# Use a writable path for SQLite
SQLITE_PATH = os.path.join(os.environ.get('PGADMIN_STORAGE_DIR', '/pgadmin4/volumes'), 'pgadmin4.db')
