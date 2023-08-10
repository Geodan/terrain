FROM tumgis/ctb-quantized-mesh:alpine
RUN apk update && apk add parallel && apk add findutils && apk add gzip

COPY process.sh /
RUN chmod +x /process.sh
RUN echo -ne "will cite" | parallel --citation || true

ENTRYPOINT ["/process.sh"]