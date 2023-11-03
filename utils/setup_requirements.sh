setup_helm() {
    if ! command -v helm &> /dev/null
    then
        curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
        chmod 700 get_helm.sh
        ./get_helm.sh
        rm get_helm.sh
    fi
    echo "Helm version: $(helm version)"
}

setup_kubectl() {
    if ! command -v kubectl &> /dev/null
    then
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x ./kubectl
        sudo mv ./kubectl /usr/local/bin/kubectl
    fi
    echo "Kubectl version: $(kubectl version --client)"
}

setup_flux() {
    if ! command -v flux &> /dev/null
    then
        curl -s https://fluxcd.io/install.sh | sudo bash
    fi
    echo "Flux version: $(flux --version)"
}

setup_kind() {
    if ! command -v kind &> /dev/null
    then
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
    fi
    echo "Kind version: $(kind version)"
}

setup_docker() {
    if ! command -v docker &> /dev/null
    then
        sudo apt-get update
        sudo apt-get install ca-certificates curl gnupg
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg

        # Add the repository to Apt sources:
        echo \
            "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
            "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    fi
    echo "Docker version: $(docker version)"
}

setup_cilium() {
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
    echo "Cilium version: $(cilium version)"
}

setup_make() {
    if ! command -v make &> /dev/null
    then
        sudo apt-get install make
    fi
    echo "Make version: $(make --version)"
}

main() {
    setup_make
    setup_docker
    setup_kind
    setup_flux
    setup_kubectl
    setup_helm
    setup_cilium
}

main
