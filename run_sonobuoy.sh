#!/usr/bin/env bash

set -eo pipefail

BASEDIR=$(dirname "$0")
CLUSTER_NAME=
#source ${BASEDIR}/set_environment.sh
export KUBERNETES_VERSION=$(cat ../../projects/kubernetes/kubernetes/${RELEASE_BRANCH}/GIT_TAG) 
export PATH=`pwd`/bin:${PATH}
#export CLUSTER_NAME=

#Downloading latest vesrion sonobuoy binary
echo "Download sonobuoy"
if [ "$(uname)" == "Darwin" ]
then
  SONOBUOY=https://github.com/vmware-tanzu/sonobuoy/releases/download/v0.52.0/sonobuoy_0.52.0_darwin_amd64.tar.gz
else
  SONOBUOY=https://github.com/vmware-tanzu/sonobuoy/releases/download/v0.52.0/sonobuoy_0.52.0_linux_386.tar.gz
fi
CONFORMANCE_IMAGE=k8s.gcr.io/conformance:${KUBERNETES_VERSION}
wget -qO- ${SONOBUOY} |tar -xz sonobuoy
mv sonobuoy $PATH
chmod 755 sonobuoy

#Testing cluster by triggering sonobuoy run
echo "Testing cluster ${CLUSTER_NAME}"
while ! ./sonobuoy --context ${CLUSTER_NAME} run --mode=certified-conformance --wait --kube-conformance-image ${CONFORMANCE_IMAGE}
do
  ./sonobuoy --context ${CLUSTER_NAME} delete --all --wait||true
  sleep 5
  COUNT=$(expr $COUNT + 1)
  if [ $COUNT -gt 3 ]
  then
    echo "Failed to run sonobuoy"
    exit 1
  fi
  echo 'Waiting for the cluster to be ready...'
done

#Monitoring test run
./sonobuoy status
while [ "$(e2e)" == "completed"]
do
    echo "$logs" 
    logs=$( ./sonobuoy logs -f )
then
    results=$(./sonobuoy --context ${CLUSTER_NAME} retrieve)
    mv $results "./${CLUSTER_NAME}/$results"
    results="./${CLUSTER_NAME}/$results"
    mkdir ./${CLUSTER_NAME}/results
    tar xzf $results -C ./${CLUSTER_NAME}/results
fi

#copying e2e.log junit_01.xml file from results intp artifacts
if [ -w /logs/artifacts ]
then
  cp ./${CLUSTER_NAME}/results/plugins/e2e/results/global/junit_01.xml /logs/artifacts
  cp ./${CLUSTER_NAME}/results/plugins/e2e/results/global/e2e.log /logs/artifacts
fi
./sonobuoy --context ${CLUSTER_NAME} e2e ${results}
./sonobuoy --context ${CLUSTER_NAME} e2e ${results} | grep 'failed tests: 0' >/dev/null


