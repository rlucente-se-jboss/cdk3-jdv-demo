#
# Starts a local single-node OpenShift cluster on the specified hypervisor.
# 
# Usage:
#   minishift start [flags]
# 
# Flags:
#       --cpus int                        Number of CPU cores to allocate to the Minishift VM. (default 2)
#       --disk-size string                Disk size to allocate to the Minishift VM. Use the format <size><unit>, where unit = b, k, m or g. (default "20g")
#       --docker-env stringArray          Environment variables to pass to the Docker daemon. Use the format <key>=<value>.
#       --forward-ports                   Use Docker port forwarding to communicate with the origin container. Requires 'socat' locally.
#       --host-config-dir string          Location of the OpenShift configuration on the Docker host. (default "/var/lib/minishift/openshift.local.config")
#       --host-data-dir string            Location of the OpenShift data on the Docker host. If not specified, etcd data will not be persisted on the host. (default "/var/lib/minishift/hostdata")
#       --host-only-cidr string           The CIDR to be used for the minishift VM. (Only supported with VirtualBox driver.) (default "192.168.99.1/24")
#       --host-pv-dir string              Directory on Docker host for OpenShift persistent volumes (default "/var/lib/minishift/openshift.local.pv")
#       --host-volumes-dir string         Location of the OpenShift volumes on the Docker host. (default "/var/lib/minishift/openshift.local.volumes")
#       --http-proxy string               HTTP proxy for virtual machine (In the format of http://<username>:<password>@<proxy_host>:<proxy_port>)
#       --https-proxy string              HTTPS proxy for virtual machine (In the format of https://<username>:<password>@<proxy_host>:<proxy_port>)
#       --insecure-registry stringSlice   Non-secure Docker registries to pass to the Docker daemon. (default [172.30.0.0/16])
#       --iso-url string                  Location of the minishift ISO. (default "https://github.com/minishift/minishift-b2d-iso/releases/download/v1.0.2/minishift-b2d.iso")
#       --memory int                      Amount of RAM to allocate to the Minishift VM. (default 2048)
#       --metrics                         Install metrics (experimental)
#       --no-proxy string                 List of hosts or subnets for which proxy should not be used.
#       --ocp-tag string                  The OpenShift Container Platform version to run, eg. v3.5.5.8. Check the available tags in https://access.redhat.com/containers/#/registry.access.redhat.com/openshift3/ose/images (default "v3.5.5.8")
#   -e, --openshift-env stringSlice       Specify key-value pairs of environment variables to set on the OpenShift container.
#       --password string                 Password for the virtual machine registration.
#       --public-hostname string          Public hostname of the OpenShift cluster.
#       --registry-mirror stringSlice     Registry mirrors to pass to the Docker daemon.
#       --routing-suffix string           Default suffix for the server routes.
#       --server-loglevel int             Log level for the OpenShift server.
#       --skip-registry-check             Skip the Docker daemon registry check.
#       --username string                 Username for the virtual machine registration.
#       --vm-driver string                The driver to use for the Minishift VM. Possible values: [virtualbox vmwarefusion xhyve] (default "xhyve")
# 
# Global Flags:
#       --alsologtostderr                  log to standard error as well as files
#       --log_backtrace_at traceLocation   when logging hits line file:N, emit a stack trace (default :0)
#       --log_dir string                   If non-empty, write log files in this directory (default "")
#       --logtostderr                      log to standard error instead of files
#       --show-libmachine-logs             Show logs from libmachine.
#       --stderrthreshold severity         logs at or above this threshold go to stderr (default 2)
#   -v, --v Level                          log level for V logs
#       --vmodule moduleSpec               comma-separated list of pattern=N settings for file-filtered logging
#

echo "*** Launch minishift ..."
minishift start --cpus 4 --disk-size 50g --memory 12288 --alsologtostderr --username 'INSERT-RHN-USERID-HERE' --password 'INSERT-PASSWORD-HERE' --metrics 

echo "*** Configure DNS resolution ..."
IP_ADDR=`minishift ip`

cat > $(brew --prefix)/etc/dnsmasq.conf <<END
address=/.${IP_ADDR}.nip.io/${IP_ADDR}
address=/.10.1.2.2.xip.io/10.1.2.2
listen-address=127.0.0.1
END

echo "Provide admin password if prompted..."
sudo launchctl unload /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist
sudo launchctl load /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist

echo "*** Configure docker environment ..."
eval $(minishift docker-env)

echo "*** Set up datavirt templates ..."
pushd ~/minishift &> /dev/null
    rm -fr library
    git clone https://github.com/openshift/library.git

    oc login https://${IP_ADDR}:8443 -u system:admin

    cd library/official/datavirt/templates
    oc create -f datavirt63-basic-s2i.json -n openshift
    oc create -f datavirt63-extensions-support-s2i.json -n openshift
    oc create -f datavirt63-secure-s2i.json -n openshift
popd &> /dev/null

# pull the images that match the jboss-datavirt63-openshift image stream
docker pull registry.access.redhat.com/jboss-datavirt-6/datavirt63-openshift:latest
docker pull registry.access.redhat.com/jboss-datavirt-6/datavirt63-openshift:1.1
docker pull registry.access.redhat.com/jboss-datavirt-6/datavirt63-openshift:1.1-7
docker pull registry.access.redhat.com/jboss-datavirt-6/datavirt63-openshift:1.0
docker pull registry.access.redhat.com/jboss-datavirt-6/datavirt63-openshift:1.0-29

