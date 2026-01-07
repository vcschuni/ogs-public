import os

# Use a writable path for SQLite and sessions
SQLITE_PATH = os.path.join('/pgadmin4/volumes', 'pgadmin4.db')
SESSION_DB_PATH = os.path.join('/pgadmin4/volumes', 'sessions.db')
