# Set default values 
input_dir=dtms
output_dir=tiles
start_zoom=15
end_zoom=0
tif_extension=tif

print_usage()
{
   # Display Help
   echo Syntax: sh 1_create_tiles.sh '[-s|e|h|i|o]'
   echo options:
   echo i     Input directory - default ${i}
   echo o     Output directory - default ${o}
   echo s     Start zoomlevel - default ${start_zoom}
   echo e     End zoomlevel - default ${end_zoom}
   echo h     Print this help
   echo
}

echo Creates Terrain Tiles from DTM tifs.
echo

# Parse input arguments (flags)
while getopts i:o:s:e:h flag
do
    case $flag in
        i) input_dir=${OPTARG};;
        o) output_dir=${OPTARG};;
        s) start_zoom=${OPTARG};;
        e) end_zoom=${OPTARG};;
        h) print_usage; exit 0;;
    esac
done

echo Input directory: ${input_dir}
echo Output directory: ${output_dir}
echo Tif extensions: ${tif_extension}
echo Start zoomlevel: ${start_zoom}
echo End zoomlevel: ${end_zoom}

# Create tile directory
if [ ! -d "${output_dir}" ];
then
    mkdir -p "${output_dir}"
    echo ${output_dir} directory created.
fi

# Check if input directory exists and has .tif files
if ! compgen -G "${input_dir}/*${tif_extension}" > /dev/null; 
then
    echo Folder ${input_dir} does not exist or does not contain ${tif_extension} files.
    exit 1
fi

echo Building virtual raster ${input_dir}/ahn.vrt...
gdalbuildvrt ${input_dir}/ahn.vrt ${input_dir}/*.${tif_extension}

# Fill nodata in tifs
echo Filling nodata values...
gdal_fillnodata.bat ${input_dir}/ahn.vrt ${input_dir}/ahn_filled.vrt

# Reproject to 4326 with vertical datum 4979 and save as tif
echo Reprojecting to 4326 with vertical datum 4979 and saving as ${input_dir}ahn_filled_4326.${tif_extension}...
gdalwarp -s_srs EPSG:7415 -t_srs EPSG:4326+4979 ${input_dir}/ahn_filled.vrt ${input_dir}ahn_filled_4326.${tif_extension}

# create quantized mesh tiles using docker image tumgis/ctb-quantized-mesh
# todo: use $pwd on Linux
echo Running ctb-tile in Docker image...
docker run -it -v D:/dev/github.com/geodan/terrain/scripts:/data tumgis/ctb-quantized-mesh ctb-tile -f Mesh -C -N -e ${end_zoom} -s ${start_zoom} -o /data/tiles /data/ahn_filled_4326.${tif_extension}
docker run -it -v D:/dev/github.com/geodan/terrain/scripts:/data tumgis/ctb-quantized-mesh ctb-tile -f Mesh -C -N -e ${end_zoom} -s ${start_zoom} -l -o /data/tiles /data/ahn_filled_4326.${tif_extension}