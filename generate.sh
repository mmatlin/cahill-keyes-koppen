# Add locally installed packages to PATH
echo "Adding locally installed packages to PATH...."
PATH=$(npm bin):$PATH

# Create output folder
echo "Creating output folder...."
mkdir -p processed_data

# Convert the Köppen climate classification data shapefile to GeoJSON (still spherical coordinates)
# https://github.com/mbostock/shapefile#shp2json
echo "Converting Köppen climate classification data shapefile to GeoJSON...."
shp2json original_data/1976-2000.shp -o processed_data/koppen.json

# Project the Köppen GeoJSON onto the Cahill–Keyes projection
# https://github.com/d3/d3-geo-projection/blob/master/README.md#geoproject
echo "Projecting the Köppen GeoJSON onto the Cahill–Keyes projection...."
geoproject --require d3=d3-geo-polygon 'd3.geoCahillKeyes()' < processed_data/koppen.json > processed_data/ck_koppen.json

# Uncomment the following line to generate a preview of the SVG created from the projected GeoJSON before feature coloration
# geo2svg -w 960 -h 960 < processed_data/ck_koppen.json > processed_data/ck_koppen.svg # pre-coloration test to make sure projection geometry is correct

# Extract the features array from the Köppen GeoJSON and convert it to newline-delimited JSON
# https://github.com/mbostock/ndjson-cli#split
echo "Extracting the features array from the Cahill–Keyes Köppen GeoJSON as NDJSON...."
ndjson-split 'd.features' < processed_data/ck_koppen.json > processed_data/ck_koppen.ndjson

# For each feature, add a new property named "fill" with the corresponding climate's color as defined in koppen_gridcodes.json
# https://github.com/mbostock/ndjson-cli#map
echo "Adding fill color properties to Cahill–Keyes Köppen NDJSON...."
ndjson-map -r d3 -r fs '(d.properties.fill = d3.color("#" + JSON.parse(fs.readFileSync("koppen_gridcodes.json"))[d.properties.GRIDCODE]).formatRgb(), d)' < processed_data/ck_koppen.ndjson > processed_data/ck_koppen_colors.ndjson

# Generate the final SVG
# https://github.com/d3/d3-geo-projection#geo2svg
echo "Generating the final SVG...."
geo2svg -n --stroke none -p 1 -w 960 -h 960 < processed_data/ck_koppen_colors.ndjson > ck_koppen_colors.svg

echo "Done!"
