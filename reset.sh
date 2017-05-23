#!/bin/bash

minishift stop
minishift delete

pushd `dirname $0` &> /dev/null
    rm -fr library jdv-demo/datasources.properties jdv-demo/jgroups.jceks jdv-demo/keystore.jks 3scale-demo/amp.yml
popd &> /dev/null

