#!/bin/bash

source $SH_ROOT_DOCKER"/a_docker.sh"

docker_images=""
docker_pss=""

function docker_clean_include() {
  if [ "$1" == "" ]; then
    str='sandbox\|none'
  else
    str="$1"
  fi
  echo "docker_clean_include: "$str
  # docker_images=$(docker images -a | grep $str | awk '{print $3}' | xargs)
  # docker_ps=$(docker ps -a | grep $str | awk '{print $1}' | xargs)
  docker_images=$(docker images -a | grep $str | awk '$3=="IMAGE" { $1-=A;  ; next } { ; A+=2; print $3 }' | xargs)
  docker_pss=$(docker ps -a | grep $str | awk '$1=="CONTAINER" { $1-=A;  ; next } { ; A+=2; print $1 }' | xargs)

  clean
}


function docker_clean_exclude() {
  if [ "$1" == "" ]; then
    str='rabbit\|zipkin\|gray\|prometheus\|grafana\|maven\|openshift\|mysql\|postgres\|mongo\|sonar\|nexus\|jfrog\|jenkins\|k8s.gcr.io'
  else
    str="$1"
  fi
  echo "docker_clean_exclude: "$str
  # docker_images=$(docker images -a | grep -v $str | awk '{print $3}' | xargs)
  # docker_ps=$(docker ps -a | grep -v $str | awk '{print $1}' | xargs)
  docker_images=$(docker images -a | grep -v $str | awk '$3=="IMAGE" { $1-=A;  ; next } { ; A+=2; print $3 }' | xargs)
  docker_pss=$(docker ps -a | grep -v $str | awk '$1=="CONTAINER" { $1-=A;  ; next } { ; A+=2; print $1 }' | xargs)

  clean
}

function clean() {
  echo "docker_pss: "$docker_pss
  clean_pss
  echo "docker_images: "$docker_images
  clean_images
}

function clean_pss() {
  for docker_ps in ${docker_pss[@]}
  do
    # docker_rm_ps $docker_ps
    docker_rm_ps $(docker ps -a -q | grep $docker_ps)
  done
}

function clean_images() {
  for docker_image in ${docker_images[@]}
  do
    docker_rm_image $docker_image
  done
}

function docker_rm_ps() {
  docker_ps=$1
  echo "docker_ps: "$docker_ps
  docker stop $docker_ps
  docker rm $docker_ps
}

function docker_rm_image() {
  docker_image=$1
  echo "docker_image: "$docker_image
  docker images --filter since=$docker_image | awk '{print $3}' | xargs docker rmi -f
  docker rmi -f $docker_image
}

function docker_build_with_name_and_tag() {
  # cd $3
  # docker build -t $1':'$2 .
  docker build -t $1':'$2 $3
}

function docker_run_internal() {
  docker_ps_name=$1
  if [ "$4" == "true" ]; then
    docker run -d --name=$docker_ps_name $docker_ps_name:$2 $3
  else
    docker run --name=$docker_ps_name $docker_ps_name:$2 $3
  fi
}

# docker_run centralize-configuration 4.1.0
function docker_run() {
  docker_rm_ps $1
  docker_run_internal $1 $2 '-p 8443:8443 -p 8444:8444 -p 18443:18443 -p 18444:18444'
}

# docker_run_bg centralize-configuration 4.1.0
function docker_run_bg() {
  docker_rm_ps $1
  docker_run_internal $1 $2 '-p 8443:8443 -p 8444:8444 -p 18443:18443 -p 18444:18444' true
}

# docker_run_append centralize-configuration 4.1.0 '-p 8443:8443 -p 8444:8444 -p 18443:18443 -p 18444:18444'
function docker_run_append() {
  docker_rm_ps $1
  docker_run_internal $1 $2 $3
}

# docker_run_bg_append centralize-configuration 4.1.0 '-p 8443:8443 -p 8444:8444 -p 18443:18443 -p 18444:18444'
function docker_run_bg_append() {
  docker_rm_ps $1
  docker_run_internal $1 $2 $3 true
}
