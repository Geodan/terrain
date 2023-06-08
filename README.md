# terrain

Scripts for creating Cesium Quantized mesh terrain tiles

Quantized mesh specs: https://github.com/CesiumGS/quantized-mesh

## Input

0.5m DTM's from https://service.pdok.nl/rws/ahn/atom/index.xml

## Samples

Utrechtse Heuvelrug

https://geodan.github.io/terrain/samples/heuvelrug/

![image](https://github.com/Geodan/terrain/assets/538812/ecbe4c78-1fcc-424a-a564-ca001a202d48)

## Docker

The Docker image contains:

- ctb-tile

- GDAL

- GDAL python tooling

- shell scripts for processing tifs to terrain tiles

Todo: Add a shell script to Docker image

### Building

```
$ docker build -t terrain_tiler .
```

### Running

```
$ docker run -it terrain-tiler /bin/bash
```

gdal_fillnodata can run by:

```
$ python /usr/local/bin/gdal_fillnodata.py
```

## Scripts

Run scripts from 'scripts' folder. 

Prerequisites:

- wget installed

- Docker installed

- Gdal installed + Python GDAL tooling

```script
$ sh 0_download.sh
$ sh 1_create_tiles.sh
$ sh 2_unzip.sh
$ sh 3_cleanup.sh
```



