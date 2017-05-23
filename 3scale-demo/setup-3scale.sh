#!/bin/bash

IP_ADDR=$(minishift ip)

curl -O -L https://raw.githubusercontent.com/3scale/3scale-amp-openshift-templates/2.0.0.GA/amp/amp.yml

# do we need to do chcat -d /root/.oc/profiles/???/volumes/vol{01..10}

oc login https://${IP_ADDR}:8443 -u developer

oc new-project 3scale-amp

oc new-app --file amp.yml --param WILDCARD_DOMAIN=amp.${IP_ADDR}.nip.io --param ADMIN_PASSWORD=3scaleUser

echo
echo "This will take awhile for all the pods to spin up.  Once they're"
echo "all running, browse to https://3scale-admin.amp.${IP_ADDR}.nip.io"
echo "and login using the admin/3scaleUser credentials."
echo

