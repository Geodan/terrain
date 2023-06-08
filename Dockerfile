from tumgis/ctb-quantized-mesh
RUN apt-get update
RUN apt-get -y install python3-pip libgdal-dev g++
RUN pip3 install GDAL==2.4.0