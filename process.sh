#!/bin/bash

# Sample reading parameter
echo $1

# todo
# - create tile subdirectory of volume mount
# - create vrt of input tifs in volume directory
# - run gdal_fillnodata on vrt
# - run gdalwarp on filled vrt
# - run cbt-tile on warped filled vrt
# - run cbt-tile on warped filled vrt with -l option
