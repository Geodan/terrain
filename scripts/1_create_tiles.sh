echo $PWD
DIR=tiles

if [ ! -d "${DIR}" ];
then
    mkdir -p "${DIR}"
    echo "${DIR} directory created."
fi

files=""
for f in $(find -name '*.tif'); do
   f="${f%.*}"
   echo "Processing file ${f}.tif..."
   gdal_fillnodata.bat ${f}.tif ${f}_filled.tif
   gdalwarp -s_srs EPSG:7415 -t_srs EPSG:3857+4979 ${f}_filled.tif ${f}_filled_3857.tif
   files="${files} ${f}_filled_3857.tif"
done

echo "files123 $files"
# todo use a vrt instead of merging?
gdal_merge.bat -o test.tif ${files}

# create quantized mesh tiles using docker image tumgis/ctb-quantized-mesh
# todo: use $pwd on Linux
docker run -it -v D:/dev/github.com/geodan/terrain/scripts:/data tumgis/ctb-quantized-mesh ctb-tile -f Mesh -C -N -e 0 -s 15 -o /data/tiles /data/test.tif
docker run -it -v D:/dev/github.com/geodan/terrain/scripts:/data tumgis/ctb-quantized-mesh ctb-tile -f Mesh -C -N -e 0 -s 15 -l -o /data/tiles /data/test.tif