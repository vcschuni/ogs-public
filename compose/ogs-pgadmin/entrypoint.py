import os
from pgadmin4 import create_app

# Ensure environment variables are set BEFORE app init
os.environ['PGADMIN_CONFIG_FILE'] = '/pgadmin4/volumes/config_local.py'
os.environ['PGADMIN_STORAGE_DIR'] = '/pgadmin4/volumes'

# Initialize pgAdmin app
application = create_app()
