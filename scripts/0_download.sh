# download two kaartbladen for now
# todo: download all kaartbladen from geojson file with kaartbladen?

DTM_DIR=dtms

if [ ! -d "${DTM_DIR}" ];
then
    mkdir -p "${DTM_DIR}"
    echo "${DTM_DIR} directory created."
fi

wget -nc https://ns_hwh.fundaments.nl/hwh-ahn/ahn4/02b_DTM_5m/M5_31GN2.zip -O "./${DTM_DIR}/M5_31GN2.zip"
wget -nc https://ns_hwh.fundaments.nl/hwh-ahn/ahn4/02b_DTM_5m/M5_31GZ2.zip -O "./${DTM_DIR}/M5_31GZ2.zip"

# Unzip all files in DTM_DIR
unzip -u "${DTM_DIR}/*.zip" -d ${DTM_DIR}

# Remove zip files
rm -f ${DTM_DIR}/*.zip