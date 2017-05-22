# 
# Configures CDK 3 on the host.
# 
# Usage:
#   minishift setup-cdk [flags]
# 
# Flags:
#       --default-vm-driver string   Sets the default VM driver. (default "xhyve")
#       --force                      Forces the deletion of the exsiting Minishift install, if it exists.
#       --minishift-home string      Sets the Minishift home directory. (default "/Users/rlucente/.minishift")
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

minishift setup-cdk --default-vm-driver virtualbox --force --alsologtostderr

# put oc command on search path
OC_PATH=$(find $HOME/.minishift -type f -name oc)
ln -sf $OC_PATH $(brew --prefix)/bin

