#!/bin/bash

minishift stop
minishift delete

rm -fr library cdk3-demo-jdv/datasources.properties cdk3-demo-jdv/jgroups.jceks cdk3-demo-jdv/keystore.jks

