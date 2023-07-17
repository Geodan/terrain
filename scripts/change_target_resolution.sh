#!/bin/bash

tr=1

echo Change target resolution for a set of images. Warning input images will be overwritten.
echo Status: Experimental script.
start_time=$(date +%s)
echo Start: $(date)

print_usage()
{
   # Display Help
   echo Syntax: '[-t|h]'
   echo options:
   echo t     Target resoultion - default $tr
   echo h     Print this help
   echo
}

# Parse input arguments (flags)
while getopts t:h flag
do
    case $flag in
        t) tr=$OPTARG;;
        h) print_usage; exit 0;;
    esac
done

echo Target resolution: $tr

echo Start processing ${tiffs} GeoTIFFS...
for f in *.tif 
do
 echo Processing ${f}...
 gdalwarp -q -tr ${tr} ${tr} $f test.tif -overwrite
 cp test.tif $f
done

rm test.tif
end_time=$(date +%s)
echo End: $(date)
elapsed_time=$((end_time-start_time))
echo Elapsed time: $elapsed_time seconds.
echo End of processing

