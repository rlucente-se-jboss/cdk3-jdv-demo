#!/bin/bash

# See https://raw.githubusercontent.com/tariq-islam/jdv-ose-demo/master/jdv-ocp-setup.sh

IP_ADDR=$(minishift ip)

OPENSHIFT_USER=developer
OPENSHIFT_PW=developer

KEYSTORE_DEFAULT=keystore.jks
KEYSTORE_DEFAULT_PASSWORD=keystorepass
KEYSTORE_DEFAULT_ALIAS=jboss

KEYSTORE_JGROUPS=jgroups.jceks
KEYSTORE_JGROUPS_PASSWORD=keystorepass
KEYSTORE_JGROUPS_ALIAS=jboss

OPENSHIFT_PROJECT=demo
OPENSHIFT_APP_NAME=datavirt-app
OPENSHIFT_APPS_DOMAIN=${IP_ADDR}.nip.io

function marquee() {
    strlen=$((${#1} + 4))
    echo
    head -c $strlen < /dev/zero | tr '\0' '*'
    echo
    echo "* $1 *"
    head -c $strlen < /dev/zero | tr '\0' '*'
    echo
}
 
marquee "Make sure we are logged in (to the right instance and as the right user)"
oc login https://${IP_ADDR}:8443 -u ${OPENSHIFT_USER} -p${OPENSHIFT_PW} --insecure-skip-tls-verify=true

marquee "Creating the authentication objects"
marquee "- Create a keystore for the data virt server"
[ -f ${KEYSTORE_DEFAULT} ] || \
    keytool -genkeypair -keystore ${KEYSTORE_DEFAULT} -storepass ${KEYSTORE_DEFAULT_PASSWORD} \
        -keyalg RSA -alias ${KEYSTORE_DEFAULT_ALIAS} -dname "CN=${OPENSHIFT_USER}" \
        -keypass ${KEYSTORE_DEFAULT_PASSWORD} || \
    { echo "FAILED: could not create the server keystore" && exit 1; }

marquee "- Create a keystore for the data virt server's jgroups cluster"
[ -f ${KEYSTORE_JGROUPS} ] || \
    keytool -genseckey -keystore ${KEYSTORE_JGROUPS} -storepass ${KEYSTORE_JGROUPS_PASSWORD} \
        -alias ${KEYSTORE_JGROUPS_ALIAS} -dname "CN=${OPENSHIFT_USER}" \
        -keypass ${KEYSTORE_JGROUPS_PASSWORD} -storetype JCEKS || \
    { echo "FAILED: could not create the jgroups keystore" && exit 1; }

marquee "- Verify the contents of the keystore"
[ "`keytool -list -keystore ${KEYSTORE_DEFAULT} -storepass ${KEYSTORE_DEFAULT_PASSWORD} | grep ${KEYSTORE_DEFAULT_ALIAS} | wc -l`" == 0 ] && echo "FAILED" && exit 1
marquee "- Verify the contents of the keystore"
[ "`keytool -list -keystore ${KEYSTORE_JGROUPS} -storepass ${KEYSTORE_JGROUPS_PASSWORD} -storetype JCEKS | grep ${KEYSTORE_JGROUPS_ALIAS} | wc -l`" == 0 ] && echo "FAILED: could not verify the jgroups keystore was created successfully" && exit 1

marquee 'Creating a new project called jdv-demo'
oc new-project ${OPENSHIFT_PROJECT}

marquee 'Creating a service account and accompanying secret for use by the data virt application'
oc get serviceaccounts datavirt-service-account &> /dev/null || echo '{"kind": "ServiceAccount", "apiVersion": "v1", "metadata": {"name": "datavirt-service-account"}}' | oc create -f - || { echo "FAILED: could not create datavirt service account" && exit 1; }

marquee 'Creating secrets for the JDV server'
oc get secret datavirt-app-secret &> /dev/null || oc secrets new datavirt-app-secret ${KEYSTORE_DEFAULT} ${KEYSTORE_JGROUPS}

oc get sa/datavirt-service-account -o json | grep datavirt-app-secret &> /dev/null || oc secrets link datavirt-service-account datavirt-app-secret || { echo "FAILED: could not link secret to service account" && exit 1; }

marquee 'Retrieving datasource properties (market data flat file and country list web service hosted on public internet)'
{ [ -f datasources.properties ] || curl https://raw.githubusercontent.com/cvanball/jdv-ose-demo/master/extensions/datasources.properties -o datasources.properties ; } && { oc secrets new datavirt-app-config datasources.properties  || { echo "FAILED" && exit 1; } ; }

marquee 'Deploying JDV quickstart template with default values'
oc get dc/datavirt-app &> /dev/null || oc new-app --template=datavirt63-extensions-support-s2i \
    --param=APPLICATION_NAME=${OPENSHIFT_APP_NAME} \
    --param=SOURCE_REPOSITORY_URL=https://github.com/cvanball/jdv-ose-demo \
    --param=CONTEXT_DIR=vdb \
    --param=EXTENSIONS_REPOSITORY_URL=https://github.com/cvanball/jdv-ose-demo \
    --param=EXTENSIONS_DIR=extensions \
    --param=SERVICE_ACCOUNT_NAME=datavirt-service-account \
    --param=HTTPS_SECRET=datavirt-app-secret \
    --param=HTTPS_KEYSTORE=${KEYSTORE_DEFAULT} \
    --param=HTTPS_KEYSTORE_TYPE=JKS \
    --param=HTTPS_NAME=${KEYSTORE_DEFAULT_ALIAS} \
    --param=HTTPS_PASSWORD=${KEYSTORE_DEFAULT_PASSWORD} \
    --param=TEIID_USERNAME=teiidUser \
    --param=TEIID_PASSWORD=redhat1! \
    --param=IMAGE_STREAM_NAMESPACE=openshift \
    --param=JGROUPS_ENCRYPT_SECRET=datavirt-app-secret \
    --param=JGROUPS_ENCRYPT_KEYSTORE=${KEYSTORE_JGROUPS} \
    --param=JGROUPS_ENCRYPT_NAME=${KEYSTORE_JGROUPS_ALIAS} \
    --param=JGROUPS_ENCRYPT_PASSWORD=${KEYSTORE_JGROUPS_PASSWORD} \
    -l app=${OPENSHIFT_APP_NAME}

echo "==============================================="
echo '--> Example data service access'
echo '	--> The following urls will allow you to access the vdbs (of which there are two) via OData2 and OData4:'
echo '	--> by default, JDV secures odata sources with the standard teiid-security security domain.'
echo '	--> if prompted for username/password: username = teiidUser password = redhat1!'
# reminder: for curl, use curl -u teiidUser:redhat1!
echo "==============================================="
echo "	--> Metadata for Country web service"
echo "		--> (odata 2) http://${OPENSHIFT_APP_NAME}-${OPENSHIFT_PROJECT}.${OPENSHIFT_APPS_DOMAIN}"'/odata/country-ws/$metadata'
echo "		--> (odata 4) http://${OPENSHIFT_APP_NAME}-${OPENSHIFT_PROJECT}.${OPENSHIFT_APPS_DOMAIN}"'/odata4/country-ws/country/$metadata'
echo "	--> Querying data from Country web service"
echo "		--> (odata 2) http://${OPENSHIFT_APP_NAME}-${OPENSHIFT_PROJECT}.${OPENSHIFT_APPS_DOMAIN}"'/odata/country-ws/country.Countries?$format=json'
echo "		--> (odata 4) http://${OPENSHIFT_APP_NAME}-${OPENSHIFT_PROJECT}.${OPENSHIFT_APPS_DOMAIN}"'/odata4/country-ws/country/Countries?$format=json'
echo "	--> Querying data from Country web service via primary key"
echo "		--> (odata 2) http://${OPENSHIFT_APP_NAME}-${OPENSHIFT_PROJECT}.${OPENSHIFT_APPS_DOMAIN}"'/odata/country-ws/country.Countries('\''Zimbabwe'\'')?$format=json '
echo "		--> (odata 4) http://${OPENSHIFT_APP_NAME}-${OPENSHIFT_PROJECT}.${OPENSHIFT_APPS_DOMAIN}"'/odata4/country-ws/country/Countries('\''Zimbabwe'\'')?$format=json'
echo "	--> Querying data from Country web service and returning specific fields"
echo "		--> (odata 2) http://${OPENSHIFT_APP_NAME}-${OPENSHIFT_PROJECT}.${OPENSHIFT_APPS_DOMAIN}"'/odata/country-ws/country.Countries?$select=name&$format=json'
echo "		--> (odata 4) http://${OPENSHIFT_APP_NAME}-${OPENSHIFT_PROJECT}.${OPENSHIFT_APPS_DOMAIN}"'/odata4/country-ws/country/Countries?$select=name&$format=json'
echo "	--> Querying data from Country web service and showing top 5 results"
echo "		--> (odata 2) http://${OPENSHIFT_APP_NAME}-${OPENSHIFT_PROJECT}.${OPENSHIFT_APPS_DOMAIN}"'/odata/country-ws/country.Countries?$top=5&$format=json'
echo "		--> (odata 4) http://${OPENSHIFT_APP_NAME}-${OPENSHIFT_PROJECT}.${OPENSHIFT_APPS_DOMAIN}"'/odata4/country-ws/country/Countries?$top=5&$format=json'
echo "==============================================="

echo "Done."
