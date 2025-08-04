#!/bin/bash

service_name=junctionmed
image_name=mago-jm
planet=neptune
service_port=59701
workdir=mago-services/${image_name}
modeldir=${workdir}/models
dc_yml=tools/docker-compose.yml

# Make service folder
[ ! -d ${workdir} ] && mkdir -p ${workdir}  && echo "'${workdir}' folder is created."
[ ! -d ${modeldir} ] && mkdir -p ${modeldir}  && echo "'${modeldir}' folder is created."

# Modify docker-compose.yml
[ ! -f ${dc_yml} ] && echo "'${dc_yml} does not exist, check it."

if [ ! -f ${workdir}/docker-compose.yml ]; then
    cp ${dc_yml} ${workdir}/
    sed -i "s:<service_name>:${service_name}:g" ${workdir}/docker-compose.yml
    sed -i "s:<serivce_port>:${service_port}:g" ${workdir}/docker-compose.yml
    sed -i "s:<image_name>:${image_name}:g" ${workdir}/docker-compose.yml
    sed -i "s:<planet>:${planet}:g" ${workdir}/docker-compose.yml
fi

# Download docker image
cd tools
./pull_image.sh ${image_name}
cd -

# Dwonload models
cd ${modeldir}

for model_name in speech_recognition speech_activity_detection emotion_recognition text_normalization named_entity_recognition natural_language_understanding; do
   aws s3 sync s3://mago-ai-models/${model_name} ${model_name}
done

cd -
