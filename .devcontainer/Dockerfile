FROM ubuntu as base

# ------------------------------------------------------
# Devcontainer image
FROM base AS workspace
ARG REMOTE_USER
ARG REMOTE_UID
ARG REMOTE_GID

# Tools setup
RUN apt update && apt install -y wget curl gnupg software-properties-common \
    && wget -O - https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list \
    && apt update && apt install -y terraform

RUN apt update && apt install -y skopeo

RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 \
    && chmod 700 get_helm.sh \
    && ./get_helm.sh

RUN curl -s https://fluxcd.io/install.sh | bash

RUN arch=$(dpkg --print-architecture) \
    && curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${arch}/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm kubectl

# User setup
RUN set -eux; \
    if ! getent group "${REMOTE_USER}" >/dev/null; then \
        if getent group "${REMOTE_GID}" >/dev/null; then \
            group_name="$(getent group "${REMOTE_GID}" | cut -d: -f1)"; \
        else \
            addgroup --gid "${REMOTE_GID}" "${REMOTE_USER}"; \
            group_name="${REMOTE_USER}"; \
        fi; \
    else \
        group_name="${REMOTE_USER}"; \
    fi; \
    if ! id -u "${REMOTE_USER}" >/dev/null 2>&1; then \
        if getent passwd "${REMOTE_UID}" >/dev/null; then \
            existing_user="$(getent passwd "${REMOTE_UID}" | cut -d: -f1)"; \
            usermod -l "${REMOTE_USER}" "${existing_user}"; \
            usermod -d "/home/${REMOTE_USER}" -m "${REMOTE_USER}" || true; \
            usermod -g "${group_name}" "${REMOTE_USER}"; \
        else \
            adduser --disabled-password --gecos "" --uid "${REMOTE_UID}" --gid "${REMOTE_GID}" "${REMOTE_USER}"; \
        fi; \
    fi
ENV HOME /home/${REMOTE_USER}
ENV LC_ALL=C.UTF-8
USER ${REMOTE_USER}
