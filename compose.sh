#!/bin/bash

docker run -it --rm --privileged -v $HOME/.docker:/root/.docker -v /var/run/docker.sock:/var/run/docker.sock -v /home/cis/kub/cis-startup/:/workdir -w /workdir docker/compose:1.26.0 "$@"
