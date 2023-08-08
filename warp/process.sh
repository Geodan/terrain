#!/bin/bash

version=1.1
tmp_dir=tmp
default_s_srs=EPSG:7415
s_srs=""
md=100
jobs=5

echo Terrain tiler $version - Warp
start_time=$(date +%s)
echo Start: $(date)

print_usage()
{
   # Display Help
   echo Syntax: '[-c|m|j|h]'
   echo options:
   echo c     Source s_srs - default $s_srs
   echo m     fillnodata maxdistance in pixels - default $md
   echo j     Number of jobs - default $jobs
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
    find ./ -maxdepth 1 -type f -iname '*.tif' | parallel --bar -j ${jobs} warp_tiff ${tmp_dir} ${md} ${s_srs}
}
export -f warp_tiff

# Parse input arguments (flags)
while getopts c:m:j:h flag
do
    case $flag in
        c) s_srs=$OPTARG;;
        m) md=$OPTARG;;
        j) jobs=$OPTARG;;
        h) print_usage; exit 0;;
    esac
done

echo Temp directory: $tmp_dir
echo Fillnodata maxdistance: $md
echo Jobs: $jobs

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

# Check on s_srs, if not set, try to find it from first GeoTIFF
if [[ $s_srs == "" ]]
then
    echo s_srs not set, trying to detect it from first GeoTIFF...
    # get the first tif
    first_tif=$(find ./ -maxdepth 1 -type f -iname '*.tif' | head -1)
    # get the epsg code
    epsg_first_tif=$(gdalsrsinfo -o epsg $first_tif)

    echo EPSG of first tif: ${epsg_first_tif} 
    prefix="${epsg_first_tif:1:4}"

    if [[ $prefix == "EPSG" ]]; then
        if [[ $epsg_first_tif != *"EPSG:-1" ]]
        then
            # real epsg code found in first tif
            if [[ $epsg_first_tif == *"EPSG:28992" ]]
            then
                echo make s_srs epsg:7415 in case of epsg:28992
                s_srs=$default_s_srs
            else
                s_srs=$epsg_first_tif
            fi
        else
            echo EPSG not found from ${first_tif}:  ${epsg_first_tif}
            echo Exit process...
            exit 1
        fi
    else
        # no epsg code detected, for example: '_Confidence in this match: 25 % EPSG:28992 Confidence in this match: 25 % EPSG:28991_'
        # use default epsg code instead
        echo EPSG not found from ${first_tif}:  ${epsg_first_tif}
        echo using default s_srs: $default_s_srs
        s_srs=$default_s_srs
    fi
fi

echo used s_srs: $s_srs

warp_tiffs

echo Building virtual raster ${tmp_dir}/ahn.vrt...
gdalbuildvrt -a_srs EPSG:4326 ${tmp_dir}/ahn.vrt ${tmp_dir}/*.tif
echo VRT created: ${tmp_dir}/ahn.vrt

end_time=$(date +%s)
echo End: $(date)
elapsed_time=$((end_time-start_time))
echo Elapsed time: $elapsed_time seconds.
echo End of processing

