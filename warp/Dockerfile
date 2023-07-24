FROM ghcr.io/osgeo/gdal:ubuntu-full-3.7.0
RUN apt-get update && apt-get install -y parallel
COPY process.sh /
RUN chmod +x /process.sh
WORKDIR /data
ENTRYPOINT ["/process.sh"]