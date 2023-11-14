#!/bin/bash
CILIUM_VERSION="1.14.4"

PRELOADED_DOCKER_IMAGES=(
    "quay.io/cilium/cilium:v${CILIUM_VERSION}"
)
SCRIPT_PATH=$(dirname $(realpath -s $0))

check_requirements() {
    # Check cgroup namespace
    local c1=$(docker exec kind-control-plane ls -al /proc/self/ns/cgroup)
    local c2=$(docker exec kind-worker ls -al /proc/self/ns/cgroup)
    local c3=$(ls -al /proc/self/ns/cgroup)
    if [[ "$c1" == "$c2" && "$c2" == "$c3" ]]; then
        echo "ERROR: Some containers share cgroup namespace."
        exit 1
    fi
    echo "OK - Docker cgroup namespace"

    # Check docker cgroup driver
    local c1="$(docker info -f '{{.CgroupVersion}}')"
    if [[ "$c1" != "2" ]]; then
        echo "ERROR: Docker do not use cgroup driver in version."
        exit 1
    fi
    echo "OK - Docker cgroup version"
}

preload_images() {
    for image in ${PRELOADED_DOCKER_IMAGES[@]}; do
        echo "Preloading $image"
        docker pull $image
        kind load docker-image $image
    done
}

install_cilium() {
    # Install cilium CNI plugin using helm
    helm repo add cilium https://helm.cilium.io/
    helm repo update
    helm install cilium cilium/cilium \
        --version ${CILIUM_VERSION} \
        --namespace kube-system \
        --values ${SCRIPT_PATH}/../../flux/infrastructure/base/cilium/main_values.yaml

    cilium status --wait
}

main() {
    check_requirements
    preload_images
    # There is no CNI on kind, so we need to install cilium before we can install flux
    install_cilium
}

main
