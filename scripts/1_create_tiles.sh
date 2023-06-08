echo $PWD
TILE_DIR=tiles
DTM_DIR=dtms

if [ ! -d "${TILE_DIR}" ];
then
    mkdir -p "${TILE_DIR}"
    echo "${TILE_DIR} directory created."
fi

echo "Building virtual raster ${DTM_DIR}/ahn.vrt..."
gdalbuildvrt ${DTM_DIR}/ahn.vrt ${DTM_DIR}/*.TIF

# Fill nodata in tifs
echo "Filling nodata values..."
gdal_fillnodata.bat ${DTM_DIR}/ahn.vrt ${DTM_DIR}/ahn_filled.vrt

# Reproject to 4326 with vertical datum 4979 and save as tif
echo "Reprojecting to 4326 with vertical datum 4979 and saving as ahn_filled_4326.tif..."
gdalwarp -s_srs EPSG:7415 -t_srs EPSG:4326+4979 ${DTM_DIR}/ahn_filled.vrt ahn_filled_4326.tif

# create quantized mesh tiles using docker image tumgis/ctb-quantized-mesh
# todo: use $pwd on Linux
echo "Running ctb-tile in Docker image..."
docker run -it -v D:/dev/github.com/geodan/terrain/scripts:/data tumgis/ctb-quantized-mesh ctb-tile -f Mesh -C -N -e 0 -s 15 -o /data/tiles /data/ahn_filled_4326.tif
docker run -it -v D:/dev/github.com/geodan/terrain/scripts:/data tumgis/ctb-quantized-mesh ctb-tile -f Mesh -C -N -e 0 -s 15 -l -o /data/tiles /data/ahn_filled_4326.tif