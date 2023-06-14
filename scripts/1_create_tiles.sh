#!/bin/sh
# Set default values 
input_dir=dtms
output_dir=tiles
tmp_dir=tmp
start_zoom=15
end_zoom=0
tif_extension=TIF
s_srs=EPSG:7415
volume_mount=/mnt/d/dev/github.com/geodan/terrain/scripts

print_usage()
{
   # Display Help
   echo Syntax: sh 1_create_tiles.sh '[-s|e|h|i|o]'
   echo options:
   echo i     Input directory - default $input_dir
   echo o     Output directory - default $output_dir
   echo s     Start zoomlevel - default $start_zoom
   echo e     End zoomlevel - default $end_zoom
   echo h     Print this help
   echo
}

echo Creates Terrain Tiles from DTM tifs.
echo
start_time=$(date +%s)
echo Start: $(date)

# Parse input arguments (flags)
while getopts i:o:s:e:h flag
do
    case $flag in
        i) input_dir=$OPTARG;;
        o) output_dir=$OPTARG;;
        s) start_zoom=$OPTARG;;
        e) end_zoom=$OPTARG;;
        h) print_usage; exit 0;;
    esac
done

echo Input directory: $input_dir
echo Output directory: $output_dir
echo Tif extension: $tif_extension
echo Start zoomlevel: $start_zoom
echo End zoomlevel: $end_zoom
echo Source SRS: $s_srs

# Create tmp directory
if [ ! -d "$tmp_dir" ];
then
    mkdir -p "$tmp_dir"
    echo $tmp_dir directory created.
fi

# Create output directory
if [ ! -d "$output_dir" ];
then
    mkdir -p "$output_dir"
    echo $output_dir directory created.
fi

: <<'END'

# Check if input directory exists and has .tif files
if ! compgen -G "${input_dir}/*${tif_extension}" > /dev/null; 
then
    echo Folder ${input_dir} does not exist or does not contain ${tif_extension} files.
    exit 1
fi

for f in $(find ${input_dir}/*.${tif_extension}); do
    echo "Processing file $f..."
    f_out=$(basename $f)  
    filename="${f_out%.*}"

    gdal_fillnodata.bat $f ${tmp_dir}/${filename}_filled.$tif_extension
    gdalwarp -s_srs $s_srs -t_srs EPSG:4326+4979 ${tmp_dir}/${filename}_filled.${tif_extension} ${tmp_dir}/${filename}_filled_4326.${tif_extension}
    rm ${tmp_dir}/${filename}_filled.${tif_extension}
done

END

echo Building virtual raster ${tmp_dir}/ahn.vrt...
gdalbuildvrt -a_srs EPSG:4326 ${tmp_dir}/ahn.vrt ${tmp_dir}/*.${tif_extension} 

# create quantized mesh tiles for level 15-9 using docker image tumgis/ctb-quantized-mesh
# todo: use $pwd on Linux
echo Running ctb-tile in Docker image...gdalbuild
docker run -v ${volume_mount}:/data tumgis/ctb-quantized-mesh ctb-tile -f Mesh -C -N -e 9 -s ${start_zoom} -o ${output_dir} ${tmp_dir}/ahn.vrt

# create layer.json file
docker run -v ${volume_mount}:/data tumgis/ctb-quantized-mesh ctb-tile -f Mesh -C -N -e ${end_zoom} -s ${start_zoom} -l -o ${output_dir} ${tmp_dir}/ahn.vrt

# start workaround for level 8 - 0

# Create output directory
tmplevel9=tmplevel9
if [ ! -d "$tmplevel9" ];
then
    mkdir -p "$tmplevel9"
    echo  $tmplevel9 directory created.
fi

# generate GeoTIFF tiles on level 9
docker run -v ${volume_mount}:/data tumgis/ctb-quantized-mesh ctb-tile --output-format GTiff --output-dir ${tmplevel9} -s 9 -e 9 ${tmp_dir}/ahn.vrt

# create VRT for GeoTIFF tiles on level 9
gdalbuildvrt ${tmp_dir}/level9.vrt ./${tmplevel9}/9/*/*.tif

# Make terrain tiles for level 8-0 
docker run -v ${volume_mount}:/data tumgis/ctb-quantized-mesh ctb-tile -f Mesh -C -N -e ${end_zoom} -s 8 -l -o ${output_dir} ${tmp_dir}/level9.vrt

# end workaround for level 8 - 0

# todo: cleanup
# rm -r $tmp_dir 
end_time=$(date +%s)
echo End: $(date)
elapsed_time=$((end_time-start_time))
echo Elapsed: "Elapsed Time: $elapsed_time seconds."
echo End of script.