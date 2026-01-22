#!/bin/bash
set -e

# Ensure required environment variables are set
: "${POSTGRESQL_DATA_DB:?Need to set POSTGRESQL_DATA_DB}"
: "${POSTGRESQL_SUPERUSER_USER:?Need to set POSTGRESQL_SUPERUSER_USER}"
: "${POSTGRESQL_SUPERUSER_PASSWORD:?Need to set POSTGRESQL_SUPERUSER_PASSWORD}"

# === CONFIG ===
POSTGRESQL_HOST="ogs-postgresql"
POSTGRESQL_PORT="5432"
TABLE_NAME="osm_roads"

BC_OSM_URL="https://download.geofabrik.de/north-america/canada/british-columbia-latest.osm.pbf"
WORKDIR="/tmp/osm_bc"
PBF_FILE="${WORKDIR}/british-columbia-latest.osm.pbf"

mkdir -p "$WORKDIR"

echo "Downloading BC OSM data..."
curl -L -o "$PBF_FILE" "$BC_OSM_URL"

export PGPASSWORD="$POSTGRESQL_SUPERUSER_PASSWORD"

echo "Truncating existing table if it exists..."
psql -h "$POSTGRESQL_HOST" -U "$POSTGRESQL_SUPERUSER_USER" -d "$POSTGRESQL_DATA_DB" -c "
DO \$\$
BEGIN
   IF EXISTS (SELECT FROM information_schema.tables 
              WHERE table_schema = 'public' AND table_name = '$TABLE_NAME') THEN
       TRUNCATE TABLE $TABLE_NAME;
   END IF;
END
\$\$;
"

echo "Importing roads using osm2pgsql..."
osm2pgsql \
  --database "$POSTGRESQL_DATA_DB" \
  --username "$POSTGRESQL_SUPERUSER_USER" \
  --host "$POSTGRESQL_HOST" \
  --port "$POSTGRESQL_PORT" \
  --hstore \
  --slim \
  --create \
  --tag-filter="keep highway" \
  --multi-geometry \
  --output=pgsql \
  --table="$TABLE_NAME" \
  "$PBF_FILE"

echo "Indexing geometry..."
psql -h "$POSTGRESQL_HOST" -U "$POSTGRESQL_SUPERUSER_USER" -d "$POSTGRESQL_DATA_DB" -c "CREATE INDEX IF NOT EXISTS ${TABLE_NAME}_geom_idx ON $TABLE_NAME USING GIST(way);"

echo "Done! Roads are in table '$TABLE_NAME'."
