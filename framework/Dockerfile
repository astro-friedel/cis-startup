FROM python:3

ENV PKG_DIR="/usr/local/lib/python3.6/site-packages/cis_interface"

RUN pip install cis_interface astropy requests
COPY *.sh *.yml ./

ENTRYPOINT [ "./entrypoint.sh" ]
