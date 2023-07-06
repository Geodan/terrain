# terrain

Scripts for creating Cesium Quantized mesh terrain tiles

Quantized mesh specs: https://github.com/CesiumGS/quantized-mesh

![noordwijk](https://github.com/Geodan/terrain/assets/538812/1d52b104-fa64-41be-b524-8b0a669ac842)

Docker images: 

- https://hub.docker.com/repository/docker/geodan/terrainwarp

- https://hub.docker.com/repository/docker/geodan/terraintiler

## Input

- 0.5m DTM's from https://service.pdok.nl/rws/ahn/atom/index.xml

- 5M DTM's from [GeoJSON](https://services.arcgis.com/nSZVuSZjHpEZZbRo/arcgis/rest/services/Kaartbladen_AHN3/FeatureServer/0/query?where=1%3D1&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&resultType=none&distance=0.0&units=esriSRUnit_Meter&relationParam=&returnGeodetic=false&outFields=*&returnGeometry=true&returnCentroid=false&featureEncoding=esriDefault&multipatchOption=xyFootprint&maxAllowableOffset=&geometryPrecision=&outSR=&defaultSR=&datumTransformation=&applyVCSProjection=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&returnQueryGeometry=false&returnDistinctValues=false&cacheHint=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&returnZ=false&returnM=false&returnExceededLimitFeatures=true&quantizationParameters=&sqlFormat=none&f=pgeojson&token=)

## Samples

Utrechtse Heuvelrug

https://geodan.github.io/terrain/samples/heuvelrug/

![image](https://github.com/Geodan/terrain/assets/538812/ecbe4c78-1fcc-424a-a564-ca001a202d48)

## Getting started

Download AHN3 GeoTIFF and process to terrain tiles. 

```
$ wget https://ns_hwh.fundaments.nl/hwh-ahn/ahn4/02b_DTM_5m/M5_31GN2.zip
$ unzip M5_31GN2.zip
```

![image](https://github.com/Geodan/terrain/assets/538812/49ec3561-db50-4e93-9dbd-aa49177e76a0)


Tiling on Linux:

```
$ docker run -v $(pwd):/data geodan/terrainwarp
$ docker run -v $(pwd):/data geodan/terraintiler
```

Tiling on Windows: specify the path when running the Docker image:

```
$ docker run -v d:\data:/data -it geodan/terrainwarp
$ docker run -v d:\data:/data -it geodan/terraintiler
```

A subfolder 'tiles' will be created containing  file layer json and a set of .terrain tiles in a directory per level (0-15).

Terrain tiles can be used in CesiumJS as follows:

```javascript
var terrainProvider = new Cesium.CesiumTerrainProvider({
    url : './tiles'
});
viewer.scene.terrainProvider = terrainProvider;
viewer.scene.globe.depthTestAgainstTerrain=true;
```

## Docker

The Warp Docker image contains a recent version of GDAL (3.7) and shell script for processing (gdal_fillnodata, gdalwarp, gdalbuildvrt).

The Tiler Docker image contains:

- ctb-tile (https://github.com/geo-data/cesium-terrain-builder)

- GDAL (https://github.com/OSGeo/gdal)

- GDAL python tooling

- Shell script for processing tifs to terrain tiles [process.sh](process.sh)

## Building


Warp Docker image:

```
$ docker build -t geodan/terrainwarp .
```

Tiler Docker image:

```
$ docker build -t geodan/terraintiler .
```

To build the images together use:

```
$ sh build_all.sh
```

## Running

1] Warp

Use a volume mount named 'data' in the docker image to process tif files on the host machine.

```
$ docker run -v [local_path_to_tiffs_dir]:/data -it geodan/terrainwarp
```

The script takes as input parameters:

```
Syntax: [-c|h]
options:
c Source s_srs - default EPSG:7415
h Print this help
```

Sample output:

```
Terrain tiler 0.3 - Warp
Start: Wed Jul 5 12:06:39 UTC 2023
Temp directory: tmp
Source SRS: EPSG:7415
tmp directory created.
Start processing 256 GeoTIFFS...
Processing DSM_1627_3855...
Building virtual raster tmp/ahn.vrt...
VRT created: tmp/ahn.vrt
End: Wed Jul 5 12:13:33 UTC 2023
Elapsed time: 414 seconds.
End of processing
```

2] Tiler

Running: 

```
$ docker run -v [local_path_to_tiffs_dir]:/data -it geodan/terraintiler
```

```
Syntax: [-s|b|e|o|h]
options:
o Output directory - default tiles
b Break zoomlevel - default 9
s Start zoomlevel - default 15
e End zoomlevel - default 0
h Print this help
```

Sample running Docker image with parameters - generate tiles for level 10 - 0 using '-s 10':

```
$ docker run -v [local_path_to_tiffs_dir]:/data -it geodan/terraintiler -s 10
```

Sample output:

```
Terrain tiler 0.3
Start: Wed Jun 21 09:24:39 UTC 2023
Output directory: tiles
Tif extension: TIF
Start zoomlevel: 15
Break zoomlevel: 9
End zoomlevel: 0
Delete output directory...
Directory created: tiles
Running ctb-tile from 15 to level 9...
Creating layer.json file...
Creating GTiff tiles for level 9...
Create vrt for GTiff tiles on level 9...
Run ctb tile on level 8 to 0
Cleaning up...
Unzip terrain files...
End: Wed Jun 21 09:24:45 UTC 2023
Elapsed time: 6 seconds.
End of processing
```

## Process

```mermaid
flowchart TD

subgraph Warp
    A{Start} --> B{TIF's}
    B --> C{TIFs remaining?}
    C -->|No| D[Build VRT]
    C -->|Yes| E[Select TIF]
    E --> F[Run GDAL Fill NODATA]
    F --> G[Run GDAL Warp to EPSG:4326+4979]
    G --> C
end
subgraph Tiling
    D --> H[Run CTB-TILE]
    H --> I[Unzip terrain tiles]
    I --> J[Terrain tiles ready - end]
end
```
