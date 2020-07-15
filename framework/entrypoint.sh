#!/bin/bash

export OUTPUT_DIR="${PKG_DIR}/examples/hello/"
export TEMPLATE_PATH="${PKG_DIR}/defaults.cfg"
export CFG_PATH="/root/.yggdrasil.cfg"

# Build up a parameters from our env
cat ${TEMPLATE_PATH} | sed -e "s#host:.*#host: ${RABBIT_HOST:-localhost}#" \
    -e "s#namespace:.*#namespace: ${RABBIT_NAMESPACE:-default}#" \
    -e "s#user:.*#user: ${RABBIT_USER:-guest}#" \
    -e "s#password:.*#password: ${RABBIT_PASS:-guest}#" \
    -e "s#vhost:.*#vhost: ${RABBIT_VHOST}#" > ${CFG_PATH}

# Print parameters / progress to the logs
#echo "Running hello_c with the following parameters:"
#cat ${CFG_PATH}
#echo "-------"

# Run the desired model(s)
cisrun "$@" 3>&1 2>&1
