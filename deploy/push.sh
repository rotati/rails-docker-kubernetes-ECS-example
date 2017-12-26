#!/bin/sh
set -x

LC=$(git rev-parse --short HEAD)
docker build -f Dockerfile -t rotati/webapp:${LC} .
docker push rotati/webapp:${LC}
kubectl set image deployment webapp webapp=rotati/webapp:${LC}
