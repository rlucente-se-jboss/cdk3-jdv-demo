# Overview
Automate Cojan van Ballegooijen's
[examples](https://developers.redhat.com/blog/2016/12/06/red-hat-jboss-data-virtualization-on-openshift-part-1-getting-started/)
for running JDV on Openshift.  Additionally, run the 3scale API
Management Platform on prem following Hugo Guerrero's [blog post](https://developers.redhat.com/blog/2017/05/22/how-to-setup-a-3scale-amp-on-premise-all-in-one-install/).
These scripts simplify running the demos on CDK3 using minishift.

## Disclaimer
This was tested on OSX so YMMV on other platforms.

# Setup Minishift
Install minishift on your platform.  Since I run brew on OSX, I
simply downloaded the minishift application and copied it to `$(brew --prefix)/bin`.

Once minishift is installed, simply type:

    ./setup.sh

# Start the Minishift Instance
Make sure to put the correct credentials in the `start.sh` file for
your [Red Hat Developers](https://developers.redhat.com) account.
You'll need an account for this to work.  Make sure to replace the
strings `INSERT-RHN-USERID-HERE` and `INSERT-PASSWORD-HERE` with
your credentials.  When that's done, simply type:

    . start.sh

Note that the above command is `period space start.sh` so it correctly
sets docker machine environment variables in the current shell.
This enables you to run commands like `docker images` to see what
images are in the registry.

# Stop the Minishift Instance
No special shell script here.  Just type:

    minishift stop

# Build the 3scale Demo
This is simply:

    cd 3scale-demo
    ./setup-3scale.sh
    cd ..

It will take some time for all the pods to start.  You can login
to the OpenShift console and observe the pods starting in the
3scale-amp project.

# Build the JDV Demo
Again, pretty straightforward:

    cd jdv-demo
    ./setup-jdv.sh

# What if I screw it all up?!!
No problem, got you covered:

    ./reset.sh

