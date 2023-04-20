#!/bin/bash

docker run \
  -it \
  --rm \
  -v "data:/data" \
  $(docker build . --quiet)
