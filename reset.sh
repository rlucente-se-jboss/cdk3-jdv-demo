#!/bin/bash

IP_ADDR=$(minishift ip)

oc login https://${IP_ADDR}:8443 -u developer

oc delete all --all -n 3scale-amp
oc delete project 3scale-amp

oc delete all --all -n demo
oc delete project demo

oc delete all --all -n test
oc delete project test

pushd `dirname $0` &> /dev/null
    rm -fr library jdv-demo/datasources.properties jdv-demo/jgroups.jceks jdv-demo/keystore.jks 3scale-demo/amp.yml
popd &> /dev/null

echo
echo Make sure to clean up the docker images
echo

