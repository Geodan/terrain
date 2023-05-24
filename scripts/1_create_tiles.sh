echo $PWD
DIR=tiles

if [ ! -d "${DIR}" ];
then
    mkdir -p "${DIR}"
    echo "${DIR} directory created."
fi

for f in $(find -name '*.TIF'); do
   f="${f%.*}"
   echo "Processing file ${f}.TIF..."
   gdal_fillnodata.bat ${f}.TIF ${f}_filled.TIF
   gdalwarp -t_srs EPSG:3857 ${f}_filled.TIF ${f}_filled_3857.TIF
done

gdal_merge.bat - test.TIF *_3857.TIF

# create quantized mesh tiles using docker image tumgis/ctb-quantized-mesh
# todo: use $pwd on Linux
docker run -it -v D:/dev/github.com/geodan/terrain/scripts:/data tumgis/ctb-quantized-mesh ctb-tile -f Mesh -C -N -e 0 -s 15 -o /data/tiles /data/test.TIF
docker run -it -v D:/dev/github.com/geodan/terrain/scripts:/data tumgis/ctb-quantized-mesh ctb-tile -f Mesh -C -N -e 0 -s 15 -l -o /data/tiles /data/test.TIF