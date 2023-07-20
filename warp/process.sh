#!/bin/bash

version=0.3.2
tmp_dir=tmp
s_srs=EPSG:7415
md=100

echo Terrain tiler $version - Warp
start_time=$(date +%s)
echo Start: $(date)

print_usage()
{
   # Display Help
   echo Syntax: '[-c|m|h]'
   echo options:
   echo c     Source s_srs - default $s_srs
   echo m     fillnodata maxdistance in pixels - default $md
   echo h     Print this help
   echo
}

# Parse input arguments (flags)
while getopts c:m:h flag
do
    case $flag in
        c) s_srs=$OPTARG;;
        m) md=$OPTARG;;
        h) print_usage; exit 0;;
    esac
done

echo Temp directory: $tmp_dir
echo Source SRS: $s_srs
echo Fillnodata maxdistance: $md

# Check if input directory has .tif files
tiffs=`find ./ -maxdepth 1 -type f -iname '*.tif' 2> /dev/nul | wc -l`

if ! [ $((tiffs)) -gt 0 ]
then
    echo Error input directory does not contain .TIF or .tif files.
    echo End of processing
    exit 1
fi

# Create tmp directory
if [ -d "$tmp_dir" ];
then
    echo Delete tmp directory...
    rm -r $tmp_dir 
fi

mkdir -p "$tmp_dir"
echo $tmp_dir directory created.

echo Start processing ${tiffs} GeoTIFFS...
for f in $(find ./ -maxdepth 1 -type f -iname '*.tif'); do
    f_out=$(basename $f)
    filename="${f_out%.*}"

    echo Processing $filename...

    gdal_fillnodata.py -md ${md} $f ${tmp_dir}/${filename}_filled.tif

    gdalwarp -s_srs $s_srs -t_srs EPSG:4326+4979 ${tmp_dir}/${filename}_filled.tif ${tmp_dir}/${filename}_filled_4326.tif
    rm ${tmp_dir}/${filename}_filled.tif
done

echo Building virtual raster ${tmp_dir}/ahn.vrt...
gdalbuildvrt -a_srs EPSG:4326 ${tmp_dir}/ahn.vrt ${tmp_dir}/*.tif
echo VRT created: ${tmp_dir}/ahn.vrt

end_time=$(date +%s)
echo End: $(date)
elapsed_time=$((end_time-start_time))
echo Elapsed time: $elapsed_time seconds.
echo End of processing

