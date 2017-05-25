==========================
Preparation After Destroy
==========================

When starting fresh image do the following. In terminal,

    git config --global user.name rlucente-se-jboss
    git config --global user.email rlucente@redhat.com

    git clone https://github.com/rlucente-se-jboss/phpmysqldemo.git

=======================
Source-to-Image Builds
=======================

In terminal,

    minishift ip
    oc login $(minishift ip):8443 -u developer

In browser, create new project "test"

Filter list on php

Select php:5.6

name: myphp
repo: https://github.com/rlucente-se-jboss/phpmysqldemo.git

Click “Show advanced build and deployment options” and explain

Click "Create"

In terminal,

    oc logs bc/myphp --follow

============================
Add Database to Application
============================

In browser, go to the application and show that database is missing

Click "Add to Project"

In the "Browse Catalog" tab, select "Data Stores" then select "MySQL".  In the template, set the username, password, and database to "myphp" then click "Create".

Wait for mysql to come up

In terminal,

    oc login https://$(minishift ip):8443 -u developer
    oc project test

    oc env dc/myphp \
        MYSQL_SERVICE_HOST=mysql.test.svc.cluster.local \
        MYSQL_SERVICE_PORT=3306 \
        MYSQL_SERVICE_DATABASE=myphp \
        MYSQL_SERVICE_USERNAME=myphp \
        MYSQL_SERVICE_PASSWORD=myphp

Refresh application tab to show that database now working

In browser, select the mysql pod and then click the "Terminal" tab.

    mysql -h 127.0.01 -u myphp -P 3306 -pmyphp myphp
    show tables;
    select * from visitors;
    quit
    exit

==================
Scale Application
==================

Scale up number of pods to four

Refresh app tab, but show that session affinity prevents round robin

In terminal, use curl to show round robin haproxy pool

    curl -L -s http://myphp-test.192.168.99.100.nip.io &> /dev/null
    curl -L -s http://myphp-test.192.168.99.100.nip.io &> /dev/null
    curl -L -s http://myphp-test.192.168.99.100.nip.io &> /dev/null
    curl -L -s http://myphp-test.192.168.99.100.nip.io &> /dev/null

In browser,

Refresh application tab to show that round robin pool has worked

==============
Show Recovery
==============

In terminal,

    oc get pods
    oc delete pod myphp-<pod>

In browser, show recovery

====================
Rebuild Application
====================

Make change to app.  In terminal,

    cd phpmysqldemo

    *Make some change*
    
    git commit -am "modify header"
    git push -u origin master

In browser,

Start a new build (Browse/Builds/myphp then click "Start Build")

Show rolling upgrade to new code

Refresh app web tab to show change

Reissue curl commands then refresh app in browser to show that internal IPs have changed

=====================
Rollback to Previous
=====================

In browser,

Select Browse/Deployments/myphp

Show various deployments

Rollback to prior deployment

In terminal,

Use curl again to show that container IPs have changed

===============
Clean Shutdown
===============

In terminal,

    oc delete all --all -n test
    oc delete project test
    
    oc scale --replicas=0 rc/gogs-1 -n demo
    oc scale --replicas=0 rc/gogs-postgresql-1 -n demo
    
Wait for the gogs pods to terminate.  Make sure to remove all the
172.30.244.8:5000/test/myphp docker images using the commands:

    docker images
    docker rmi <each-image-id>

Shutdown the openshift services:

    sudo systemctl stop openshift
    sudo systemctl stop docker

======
Notes
======

Things to talk about while waiting for builds:
- Browse > Builds, Deployments, ImageStreams, Pods, Services
- Build types: S2I, Docker, Custom and straight docker image deploy
- Templates
- Webhooks and Image Change Triggers

