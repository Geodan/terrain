#!/bin/bash

version=0.3.1

# Set default values 
output_dir=tiles
tmp_dir=tmp
start_zoom=15
break_zoom=9
end_zoom=0
# Sample reading parameter
echo Terrain tiler $version - Step 2/2 Tiling
start_time=$(date +%s)
echo Start: $(date)

print_usage()
{
   # Display Help
   echo Syntax: '[b|s|e|o|h]'
   echo options:
   echo o     Output directory - default $output_dir
   echo s     Start zoomlevel - default $start_zoom   
   echo b     Break zoomlevel - default $break_zoom
   echo e     End zoomlevel - default $end_zoom
   echo h     Print this help
   echo
}

# Parse input arguments (flags)
while getopts s:e:b:o:h flag
do
    case $flag in
        o) output_dir=$OPTARG;;
        s) start_zoom=$OPTARG;;
        b) break_zoom=$OPTARG;;
        e) end_zoom=$OPTARG;;
        h) print_usage; exit 0;;
    esac
done

echo Output directory: $output_dir
echo Start zoomlevel: $start_zoom
echo Break zoomlevel: $break_zoom
echo End zoomlevel: $end_zoom

# Check on tmp dir
if [ ! -d "$tmp_dir" ];
then
    echo Missing subdirectory: $tmp_dir
    echo Run terrainwarp first
    echo exit process
    exit 1
fi

# Check on ahn.vrt in tmp dir
if [ ! -f "${tmp_dir}/ahn.vrt" ];
then
    echo Missing file: ahn.vrt in directory $tmp_dir
    echo Run terrainwarp first
    echo exit process
    exit 1
fi


# check if $start_zoom, $break_zoom and $end_zoom are in order
# if ((start_zoom < end_zoom)); then
if ! ([ $start_zoom -gt $break_zoom ] && [ $break_zoom -gt $end_zoom ])
then
    echo Error: Zoom levels not in decreasing order: $start_zoom, $break_zoom, $end_zoom
    echo End of processing
    exit 1
fi

# Create output directory
if [ -d "$output_dir" ];
then
    echo Delete output directory...
    rm -r $output_dir 
fi

mkdir -p "$output_dir"
echo Directory created: $output_dir

# create quantized mesh tiles for level start_zoom to break_zoom (9) using ctb-tile
echo Running ctb-tile from ${start_zoom} to level ${break_zoom}...
ctb-tile -f Mesh -C -N -e ${break_zoom} -s ${start_zoom} -q -o ${output_dir} ${tmp_dir}/ahn.vrt

#create layer.json file
echo Creating layer.json file...
ctb-tile -f Mesh -q -C -N -e ${end_zoom} -s ${start_zoom} -c 1 -l -o ${output_dir} ${tmp_dir}/ahn.vrt

# start workaround for level 8 - 0

# generate GeoTIFF tiles on level break_zoom
echo Creating GTiff tiles for level ${break_zoom}...
ctb-tile --output-format GTiff --output-dir ${tmp_dir} -q -s ${break_zoom} -e ${break_zoom} ${tmp_dir}/ahn.vrt

# create VRT for GeoTIFF tiles on level break_zoom
echo Create vrt for GTiff tiles on level ${break_zoom}...
gdalbuildvrt -q ${tmp_dir}/level${break_zoom}.vrt ./${tmp_dir}/${break_zoom}/*/*.tif

# Make terrain tiles for level ${break_zoom}-1 to 0 
echo Run ctb tile on level $((break_zoom-1)) to 0
ctb-tile -f Mesh -C -N -e ${end_zoom} -q -s $((break_zoom-1)) -o ${output_dir} ${tmp_dir}/level${break_zoom}.vrt

# end workaround for level break_zoom - 0
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