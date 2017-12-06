#!/bin/bash

OUTPUT_DIR="/usr/local/lib/python2.7/site-packages/cis_interface/examples/hello/"
CFG_PATH="/root/.cis_interface.cfg"
TEMPLATE_PATH="./cfg.template.yml"

# Build up a parameters from our env
cat ${TEMPLATE_PATH} | sed -e "s#host:.*#host: ${RABBIT_HOST:-localhost}#" \
    -e "s#namespace:.*#namespace: ${RABBIT_NAMESPACE}#" \
    -e "s#user:.*#user: ${RABBIT_USER:-guest}#" \
    -e "s#password:.*#password: ${RABBIT_PASS:-guest}#" \
    -e "s#vhost:.*#vhost: ${RABBIT_VHOST}#" > ${CFG_PATH}

# Print parameters / progress to the logs
#echo "Running hello_c with the following parameters:"
#cat ${CFG_PATH}
#echo "-------"

# Run the hello_c model
cd /usr/local/lib/python2.7/site-packages/cis_interface/examples/hello
cisrun ${YAML_FILES}

#echo ''
#echo 'Job complete!'

# TODO: Print Output file names/contents?
#echo "Output directory:"
#du -a $OUTPUT_DIR
