#!/bin/bash
CILIUM_VERSION="1.14.2"
FLUX_VERSION="1.0.1"

DOCKER_IMAGES=(
    "quay.io/cilium/cilium:v${CILIUM_VERSION}"
    "ghcr.io/fluxcd/kustomize-controller:v${FLUX_VERSION}"
)
SCRIPT_PATH=$(dirname $(realpath -s $0))

check_requirements() {
    local c1=$(docker exec kind-control-plane ls -al /proc/self/ns/cgroup)
    local c2=$(docker exec kind-worker ls -al /proc/self/ns/cgroup)
    local c3=$(ls -al /proc/self/ns/cgroup)
    if [[ "$c1" == "$c2" && "$c2" == "$c3" ]]; then
        echo "ERROR: Contaiers are not running in a unique namespace."
        exit 1
    fi
}

preload_images() {
    for image in ${DOCKER_IMAGES[@]}; do
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
        --values ${SCRIPT_PATH}/../flux/infrastructure/base/cilium/values.yaml

    # Download and install cilium cli
    if ! command -v cilium &> /dev/null
    then
        CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
        CLI_ARCH=amd64
        if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
        curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
        sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
        sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
        rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
    fi

    cilium status --wait
}

main() {
    preload_images
    # There is no CNI on kind, so we need to install cilium before we can install flux
    install_cilium
}

main
