#!/bin/bash

# Set default values 
output_dir=tiles
tmp_dir=tmp
start_zoom=15
end_zoom=0
tif_extension=TIF
s_srs=EPSG:7415

# Sample reading parameter
echo Terrain tiler 0.1
echo Startup parameters: $1
echo Current directory: $PWD
start_time=$(date +%s)
echo Start: $(date)

print_usage()
{
   # Display Help
   echo Syntax: '[-c|s|e|o|h]'
   echo options:
   echo c     Source s_srs - default $s_srs
   echo o     Output directory - default $output_dir
   echo s     Start zoomlevel - default $start_zoom
   echo e     End zoomlevel - default $end_zoom
   echo h     Print this help
   echo
}

# Parse input arguments (flags)
while getopts c:s:e:o:h flag
do
    case $flag in
        c) s_srs=$OPTARG;;
        o) output_dir=$OPTARG;;
        s) start_zoom=$OPTARG;;
        e) end_zoom=$OPTARG;;
        h) print_usage; exit 0;;
    esac
done

echo Output directory: $output_dir
echo Tif extension: $tif_extension
echo Start zoomlevel: $start_zoom
echo End zoomlevel: $end_zoom
echo Source SRS: $s_srs

# Check if input directory has .tif files
if ! ls *.${tif_extension} >/dev/null 2>&1;
then
    echo Error input directory does not contain ${tif_extension} files.
    echo End of processing
    exit 1
fi

# Create tmp directory
if [ ! -d "$tmp_dir" ];
then
    mkdir -p "$tmp_dir"
    echo $tmp_dir directory created.
fi

# Create output directory
if [ -d "$output_dir" ];
then
    echo Delete output directory...
    rm -r $output_dir 
fi

mkdir -p "$output_dir"
echo Directory created: $output_dir

echo Start gdal_fillnodata and gdalwarp on input files...
for f in $(find *.${tif_extension}); do
    echo "Processing file $f..."
    f_out=$(basename $f)  
    filename="${f_out%.*}"

    gdal_fillnodata.py -q $f ${tmp_dir}/${filename}_filled.$tif_extension

    gdalwarp -q -s_srs $s_srs -t_srs EPSG:4326+4979 ${tmp_dir}/${filename}_filled.${tif_extension} ${tmp_dir}/${filename}_filled_4326.${tif_extension}
    rm ${tmp_dir}/${filename}_filled.${tif_extension}
done

echo Building virtual raster ${tmp_dir}/ahn.vrt...
gdalbuildvrt -q -a_srs EPSG:4326 ${tmp_dir}/ahn.vrt ${tmp_dir}/*.${tif_extension} 

# create quantized mesh tiles for level start_zoom-9 using ctb-tile
echo Running ctb-tile from ${start_zoom} to level 9...
ctb-tile -f Mesh -C -N -e 9 -s ${start_zoom} -q -o ${output_dir} ${tmp_dir}/ahn.vrt

#create layer.json file
echo Creating layer.json file...
ctb-tile -f Mesh -q -C -N -e ${end_zoom} -s ${start_zoom} -c 1 -l -o ${output_dir} ${tmp_dir}/ahn.vrt

# start workaround for level 8 - 0

# generate GeoTIFF tiles on level 9
echo Creating GTiff tiles for level 9...
ctb-tile --output-format GTiff --output-dir ${tmp_dir} -q -s 9 -e 9 ${tmp_dir}/ahn.vrt

# create VRT for GeoTIFF tiles on level 9
echo Create vrt for GTiff tiles on level 9...
gdalbuildvrt -q ${tmp_dir}/level9.vrt ./${tmp_dir}/9/*/*.tif

# Make terrain tiles for level 8-0 
echo Run ctb tile on level 8-0
ctb-tile -f Mesh -C -N -e ${end_zoom} -q -s 8 -o ${output_dir} ${tmp_dir}/level9.vrt

# end workaround for level 8 - 0
echo Cleaning up...
rm -r $tmp_dir 

echo Unzip terrain files...
for f in $(find  ${output_dir} -name '*.terrain'); do
   mv ${f} ${f}.gz
   gunzip -f -S terrain ${f}.gz
done

end_time=$(date +%s)
echo End: $(date)
elapsed_time=$((end_time-start_time))
echo Elapsed time: $elapsed_time seconds.
echo End of processing
