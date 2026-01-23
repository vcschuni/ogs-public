-----------------------------------------------------------------------------
--
-- The following will be applied to the gisdata database
--
-----------------------------------------------------------------------------

-- Enable PostGIS extensions
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS hstore;

-- Create Points of Interest (POI) table
CREATE TABLE poi (
    poi_id SERIAL PRIMARY KEY,                       -- Unique identifier
    name VARCHAR(255) NOT NULL,                      -- Official or common name
    description VARCHAR(1024),                       -- Brief description of the location
    category VARCHAR(100),                           -- Classification or tags
    authority VARCHAR(100),                          -- Data owner or responsible authority
    geometry GEOMETRY(Point, 4326) NOT NULL,         -- Spatial coordinate (WGS84)
    created_timestamp TIMESTAMPTZ DEFAULT NOW(),     -- Timestamp of creation
    created_by VARCHAR(50),                          -- User who created the record
    modified_timestamp TIMESTAMPTZ DEFAULT NOW(),    -- Timestamp of last modification
    modified_by VARCHAR(50)                          -- User who last modified the record
);

-- Add a spatial index for faster queries
CREATE INDEX idx_poi_geometry ON poi USING GIST (geometry);

-- Create a function to update modified_timestamp automatically
CREATE OR REPLACE FUNCTION update_modified_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.modified_timestamp = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger that calls the function before each update
CREATE TRIGGER trg_update_modified_timestamp
BEFORE UPDATE ON poi
FOR EACH ROW
EXECUTE FUNCTION update_modified_timestamp();

-- Insert Border Crossing Data
INSERT INTO poi (name, description, category, authority, geometry, created_by, modified_by)
VALUES ('AB/BC Border, Highway 1', 'AB/BC Border, Highway 1', 'Border Crossing', 'Nicole Hilborne', ST_SetSRID(ST_Point(-116.284361, 51.453526), 4326), 'Nicole Hilborne', 'Nicole Hilborne');

INSERT INTO poi (name, description, category, authority, geometry, created_by, modified_by)
VALUES ('Goodlow', 'AB/BC Border, Highway 103 (Goodlow)', 'Border Crossing', 'Nicole Hilborne', ST_SetSRID(ST_Point(-120.0, 56.316299), 4326), 'Nicole Hilborne', 'Nicole Hilborne');

INSERT INTO poi (name, description, category, authority, geometry, created_by, modified_by)
VALUES ('Kelly Lake', 'AB/BC Border, Highway 11 (Kelly Lake)', 'Border Crossing', 'Nicole Hilborne', ST_SetSRID(ST_Point(-120.0, 55.257893), 4326), 'Nicole Hilborne', 'Nicole Hilborne');

INSERT INTO poi (name, description, category, authority, geometry, created_by, modified_by)
VALUES ('AB/BC Border, Highway 16', 'AB/BC Border, Highway 16', 'Border Crossing', 'Nicole Hilborne', ST_SetSRID(ST_Point(-118.448582, 52.88208), 4326), 'Nicole Hilborne', 'Nicole Hilborne');

INSERT INTO poi (name, description, category, authority, geometry, created_by, modified_by)
VALUES ('Tupper', 'AB/BC Border, Highway 2 (Tupper)', 'Border Crossing', 'Nicole Hilborne', ST_SetSRID(ST_Point(-120.0, 55.48058), 4326), 'Nicole Hilborne', 'Nicole Hilborne');

INSERT INTO poi (name, description, category, authority, geometry, created_by, modified_by)
VALUES ('Sparwood', 'AB/BC Border, Highway 3 (Sparwood)', 'Border Crossing', 'Nicole Hilborne', ST_SetSRID(ST_Point(-114.691901, 49.632507), 4326), 'Nicole Hilborne', 'Nicole Hilborne');

INSERT INTO poi (name, description, category, authority, geometry, created_by, modified_by)
VALUES ('Dawson Creek', 'AB/BC Border, Highway 49 (Dawson Creek)', 'Border Crossing', 'Nicole Hilborne', ST_SetSRID(ST_Point(-120.0, 55.77819), 4326), 'Nicole Hilborne', 'Nicole Hilborne');

INSERT INTO poi (name, description, category, authority, geometry, created_by, modified_by)
VALUES ('AB/BC Border, Highway 93', 'AB/BC Border, Highway 93', 'Border Crossing', 'Nicole Hilborne', ST_SetSRID(ST_Point(-116.050258, 51.228549), 4326), 'Nicole Hilborne', 'Nicole Hilborne');

INSERT INTO poi (name, description, category, authority, geometry, created_by, modified_by)
VALUES ('Hyder/Stewart', 'AK/BC Border, Highway 37A (Hyder/Stewart)', 'Border Crossing', 'Nicole Hilborne', ST_SetSRID(ST_Point(-130.017807, 55.912026), 4326), 'Nicole Hilborne', 'Nicole Hilborne');

INSERT INTO poi (name, description, category, authority, geometry, created_by, modified_by)
VALUES ('Rykerts/Porthill', 'ID/BC Border, Highway 21 (Rykerts/Porthill)', 'Border Crossing', 'Nicole Hilborne', ST_SetSRID(ST_Point(-116.499558380350635, 48.999863107194422), 4326), 'Nicole Hilborne', 'Nicole Hilborne');

INSERT INTO poi (name, description, category, authority, geometry, created_by, modified_by)
VALUES ('Kingsgate/Eastport', 'ID/BC Border, Highway 3/95 (Kingsgate/Eastport)', 'Border Crossing', 'Nicole Hilborne', ST_SetSRID(ST_Point(-116.181439152154951, 49.00055566887081), 4326), 'Nicole Hilborne', 'Nicole Hilborne');

INSERT INTO poi (name, description, category, authority, geometry, created_by, modified_by)
VALUES ('Roosville/Port of Roosville', 'MT/BC Border, Highway 93 (Roosville/Port of Roosville)', 'Border Crossing', 'Nicole Hilborne', ST_SetSRID(ST_Point(-115.055898, 49.0), 4326), 'Nicole Hilborne', 'Nicole Hilborne');

INSERT INTO poi (name, description, category, authority, geometry, created_by, modified_by)
VALUES ('NT/BC Border, Highway 77', 'NT/BC Border, Highway 77', 'Border Crossing', 'Nicole Hilborne', ST_SetSRID(ST_Point(-122.932806, 60.0), 4326), 'Nicole Hilborne', 'Nicole Hilborne');

INSERT INTO poi (name, description, category, authority, geometry, created_by, modified_by)
VALUES ('Huntingdon/Sumas', 'WA/BC Border, Highway 11 (Huntingdon/Sumas)', 'Border Crossing', 'Nicole Hilborne', ST_SetSRID(ST_Point(-122.265219, 49.004678), 4326), 'Nicole Hilborne', 'Nicole Hilborne');

INSERT INTO poi (name, description, category, authority, geometry, created_by, modified_by)
VALUES ('Aldergrove/Lynden', 'WA/BC Border, Highway 13 (Aldergrove/Lynden)', 'Border Crossing', 'Nicole Hilborne', ST_SetSRID(ST_Point(-122.485026353146495, 49.000422384164494), 4326), 'Nicole Hilborne', 'Nicole Hilborne');

INSERT INTO poi (name, description, category, authority, geometry, created_by, modified_by)
VALUES ('Douglas Pacific', 'WA/BC Border, Highway 15 (Douglas Pacific)', 'Border Crossing', 'Nicole Hilborne', ST_SetSRID(ST_Point(-122.735322148820799, 49.00409691325109), 4326), 'Nicole Hilborne', 'Nicole Hilborne');

INSERT INTO poi (name, description, category, authority, geometry, created_by, modified_by)
VALUES ('Rossland', 'WA/BC Border, Highway 22 (Rossland)', 'Border Crossing', 'Nicole Hilborne', ST_SetSRID(ST_Point(-117.831631, 49.0), 4326), 'Nicole Hilborne', 'Nicole Hilborne');

INSERT INTO poi (name, description, category, authority, geometry, created_by, modified_by)
VALUES ('Waneta/Boundary', 'WA/BC Border, Highway 22A (Waneta/Boundary)', 'Border Crossing', 'Nicole Hilborne', ST_SetSRID(ST_Point(-117.623630000666978, 49.001101959921591), 4326), 'Nicole Hilborne', 'Nicole Hilborne');

INSERT INTO poi (name, description, category, authority, geometry, created_by, modified_by)
VALUES ('Chopaka/Nighthawk', 'WA/BC Border, Highway 3 (Chopaka/Nighthawk)', 'Border Crossing', 'Nicole Hilborne', ST_SetSRID(ST_Point(-119.671025, 49.0), 4326), 'Nicole Hilborne', 'Nicole Hilborne');

INSERT INTO poi (name, description, category, authority, geometry, created_by, modified_by)
VALUES ('Midway', 'WA/BC Border, Highway 3 (Midway)', 'Border Crossing', 'Nicole Hilborne', ST_SetSRID(ST_Point(-118.761102, 49.0), 4326), 'Nicole Hilborne', 'Nicole Hilborne');

INSERT INTO poi (name, description, category, authority, geometry, created_by, modified_by)
VALUES ('Cascade/Laurier-Christina Lake', 'WA/BC Border, Highway 3/395 (Cascade/Laurier-Christina Lake)', 'Border Crossing', 'Nicole Hilborne', ST_SetSRID(ST_Point(-118.223909, 49.0), 4326), 'Nicole Hilborne', 'Nicole Hilborne');

INSERT INTO poi (name, description, category, authority, geometry, created_by, modified_by)
VALUES ('Carson', 'WA/BC Border, Highway 41 (Carson)', 'Border Crossing', 'Nicole Hilborne', ST_SetSRID(ST_Point(-118.504168125062009, 49.00120073666416), 4326), 'Nicole Hilborne', 'Nicole Hilborne');

INSERT INTO poi (name, description, category, authority, geometry, created_by, modified_by)
VALUES ('Nelway', 'WA/BC Border, Highway 6 (Nelway)', 'Border Crossing', 'Nicole Hilborne', ST_SetSRID(ST_Point(-117.299127480480863, 49.000736300784617), 4326), 'Nicole Hilborne', 'Nicole Hilborne');

INSERT INTO poi (name, description, category, authority, geometry, created_by, modified_by)
VALUES ('Osoyoos/Oroville', 'WA/BC Border, Highway 97 (Osoyoos/Oroville)', 'Border Crossing', 'Nicole Hilborne', ST_SetSRID(ST_Point(-119.461856, 49.0), 4326), 'Nicole Hilborne', 'Nicole Hilborne');

INSERT INTO poi (name, description, category, authority, geometry, created_by, modified_by)
VALUES ('Peach Arch', 'WA/BC Border, Highway 99 (Peace Arch)', 'Border Crossing', 'Nicole Hilborne', ST_SetSRID(ST_Point(-122.755215373302391, 49.000490333275067), 4326), 'Nicole Hilborne', 'Nicole Hilborne');

INSERT INTO poi (name, description, category, authority, geometry, created_by, modified_by)
VALUES ('YT/BC Border, Highway 37', 'YT/BC Border, Highway 37', 'Border Crossing', 'Nicole Hilborne', ST_SetSRID(ST_Point(-129.052641, 60.0), 4326), 'Nicole Hilborne', 'Nicole Hilborne');

INSERT INTO poi (name, description, category, authority, geometry, created_by, modified_by)
VALUES ('YT/BC Border, Highway 97', 'YT/BC Border, Highway 97', 'Border Crossing', 'Nicole Hilborne', ST_SetSRID(ST_Point(-128.545693, 60.0), 4326), 'Nicole Hilborne', 'Nicole Hilborne');
