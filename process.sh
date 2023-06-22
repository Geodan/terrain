#!/bin/bash

# Set default values 
output_dir=tiles
tmp_dir=tmp
start_zoom=15
break_zoom=9
end_zoom=0
s_srs=EPSG:7415

# Sample reading parameter
echo Terrain tiler 0.2
start_time=$(date +%s)
echo Start: $(date)

print_usage()
{
   # Display Help
   echo Syntax: '[-c|s|b|e|o|h]'
   echo options:
   echo c     Source s_srs - default $s_srs
   echo o     Output directory - default $output_dir
   echo s     Start zoomlevel - default $start_zoom
   echo b     Break zoomlevel - default $break_zoom
   echo e     End zoomlevel - default $end_zoom
   echo h     Print this help
   echo
}

# Parse input arguments (flags)
while getopts c:s:e:b:o:h flag
do
    case $flag in
        c) s_srs=$OPTARG;;
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
echo Source SRS: $s_srs

# check if $start_zoom, $break_zoom and $end_zoom are in order
# if ((start_zoom < end_zoom)); then
if ! ([ $start_zoom -gt $break_zoom ] && [ $break_zoom -gt $end_zoom ])
then
    echo Error: Zoom levels not in decreasing order: $start_zoom, $break_zoom, $end_zoom
    echo End of processing
    exit 1
fi

# Check if input directory has .tif files
tiffs=`find . -maxdepth 1 -type f -iname *.tif 2> /dev/nul | wc -l`

if ! [ $((tiffs)) -gt 0 ]
then
    echo Error input directory does not contain .TIF or .tif files.
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

echo Start processing ${tiffs} GeoTIFFS...
for f in $(find . -maxdepth 1 -type f -iname *.tif); do
    echo -ne "$f\033[0K\r"
    f_out=$(basename $f)  
    filename="${f_out%.*}"

    gdal_fillnodata.py -q $f ${tmp_dir}/${filename}_filled.tif

    gdalwarp -q -s_srs $s_srs -t_srs EPSG:4326+4979 ${tmp_dir}/${filename}_filled.tif ${tmp_dir}/${filename}_filled_4326.tif
    rm ${tmp_dir}/${filename}_filled.tif
done

echo Building virtual raster ${tmp_dir}/ahn.vrt...
gdalbuildvrt -q -a_srs EPSG:4326 ${tmp_dir}/ahn.vrt ${tmp_dir}/*.tif

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
