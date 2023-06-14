#!/bin/bash

# Sample reading parameter
echo Terrain tiler 0.1
echo Startup parameters: $1
echo Current directory: $PWD
echo Tif files available: 
ls *.tif

# todo
# - Read startup parmeters
# - Check if there are tif files available, otherwise exit
# - create tile subdirectory of volume mount (or empty when exists?)
# - create vrt of input tifs in volume directory
# - run gdal_fillnodata on vrt
# - run gdalwarp on filled vrt
# - run cbt-tile on warped filled vrt
# - run cbt-tile on warped filled vrt with -l option
# - Sumarize and exit

echo End of processing