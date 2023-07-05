#!/bin/bash

# Builds two Docker Images:
# - geodan/terraintiler
# - geodan/terrainwarp

echo Build Docker image geodan/terraintiler

cd tiler
docker build -t geodan/terraintiler .

cd ../warp

echo Build Docker image geodan/terrainwarp

docker build -t geodan/terrainwarp .

echo End of build

