LC=$(git rev-parse --short HEAD)
docker build -t rotati/webapp:${LC} .
docker push rotati/webapp:${LC}