FROM tumgis/ctb-quantized-mesh
RUN apt-get update && apt-get install -y parallel

COPY process.sh /
RUN chmod +x /process.sh

ENTRYPOINT ["/process.sh"]