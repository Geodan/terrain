FROM ghcr.io/osgeo/gdal:ubuntu-full-3.7.0
COPY process.sh /
RUN chmod +x /process.sh
WORKDIR /data
ENTRYPOINT ["/process.sh"]