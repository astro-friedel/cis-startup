FROM python:2

ENV PKG_DIR="/usr/local/lib/python2.7/site-packages/cis_interface"

RUN pip install cis_interface astropy requests
COPY *.sh *.yml ./

CMD [ "./entrypoint.sh" ]
