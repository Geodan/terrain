print_usage()
{
   # Display Help
   echo "Creates 3D Tiles from DTM tifs."
   echo
   echo "Syntax: sh ./1_create_tiles.sh [-s|e|h]"
   echo "options:"
   echo "s     Startzoom."
   echo "e     Endzoom."
   echo "h     Print this help."
   echo
}

# Set default values 
TILE_DIR=tiles
DTM_DIR=dtms
startzoom=15
endzoom=0

# Parse input arguments (flags)
while getopts s:e:h flag
do
    case $flag in
        s) startzoom=${OPTARG};;
        e) endzoom=${OPTARG};;
        h) print_usage; exit 0;;
    esac
done

# Create tile directory
if [ ! -d "${TILE_DIR}" ];
then
    mkdir -p "${TILE_DIR}"
    echo ${TILE_DIR} directory created.
fi

# Check if dtm directory exists and has .tif files
if ! compgen -G "${DTM_DIR}/*.TIF" > /dev/null; 
then
    echo Folder ${DTM_DIR} does not exist or does not contain .tif files.
    exit 1
fi

echo Building virtual raster ${DTM_DIR}/ahn.vrt...
gdalbuildvrt ${DTM_DIR}/ahn.vrt ${DTM_DIR}/*.TIF

# Fill nodata in tifs
echo Filling nodata values...
gdal_fillnodata.bat ${DTM_DIR}/ahn.vrt ${DTM_DIR}/ahn_filled.vrt

# Reproject to 4326 with vertical datum 4979 and save as tif
echo Reprojecting to 4326 with vertical datum 4979 and saving as ${DTM_DIR}ahn_filled_4326.tif...
gdalwarp -s_srs EPSG:7415 -t_srs EPSG:4326+4979 ${DTM_DIR}/ahn_filled.vrt ${DTM_DIR}ahn_filled_4326.tif

# create quantized mesh tiles using docker image tumgis/ctb-quantized-mesh
# todo: use $pwd on Linux
echo Running ctb-tile in Docker image...
docker run -it -v D:/dev/github.com/geodan/terrain/scripts:/data tumgis/ctb-quantized-mesh ctb-tile -f Mesh -C -N -e $endzoom -s $startzoom -o /data/tiles /data/ahn_filled_4326.tif
docker run -it -v D:/dev/github.com/geodan/terrain/scripts:/data tumgis/ctb-quantized-mesh ctb-tile -f Mesh -C -N -e $endzoom -s $startzoom -l -o /data/tiles /data/ahn_filled_4326.tif