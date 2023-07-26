#!/bin/bash

version=0.3.3
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

warp_tiff()
{
    tmp_dir=$1
    md=$2
    s_srs=$3
    tiff_file=$4

    f_out=$(basename ${tiff_file})
    filename="${f_out%.*}"
    gdal_fillnodata.py -q -md ${md} ${tiff_file} ${tmp_dir}/${filename}_filled.tif
    gdalwarp -q -s_srs $s_srs -t_srs EPSG:4326+4979 ${tmp_dir}/${filename}_filled.tif ${tmp_dir}/${filename}_filled_4326.tif
    rm ${tmp_dir}/${filename}_filled.tif
}

warp_tiffs()
{
    echo Start processing ${tiffs} GeoTIFFS...
    find ./ -maxdepth 1 -type f -iname '*.tif' | parallel --bar warp_tiff ${tmp_dir} ${md} ${s_srs}
}
export -f warp_tiff

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
tiffs=`find ./ -maxdepth 1 -type f -iname '*.tif' 2> /dev/null | wc -l`

if ! [ $((tiffs)) -gt 0 ]
then
    echo Error input directory does not contain .TIF or .tif files.
    echo End of processing
    exit 1
fi

# Create tmp directory
if [ -d "$tmp_dir" ];
then
    echo A directory with the name ${tmp_dir} already exists. Please remove or rename it. Exiting...
    exit
fi

mkdir -p "$tmp_dir"
echo $tmp_dir directory created.

warp_tiffs

echo Building virtual raster ${tmp_dir}/ahn.vrt...
gdalbuildvrt -a_srs EPSG:4326 ${tmp_dir}/ahn.vrt ${tmp_dir}/*.tif
echo VRT created: ${tmp_dir}/ahn.vrt

end_time=$(date +%s)
echo End: $(date)
elapsed_time=$((end_time-start_time))
echo Elapsed time: $elapsed_time seconds.
echo End of processing

