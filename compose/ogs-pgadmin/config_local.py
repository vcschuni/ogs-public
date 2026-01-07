import os

# Use writable path for SQLite database and session storage
SQLITE_PATH = os.path.join('/pgadmin4/volumes', 'pgadmin4.db')
SESSION_DB_PATH = os.path.join('/pgadmin4/volumes', 'sessions.db')
