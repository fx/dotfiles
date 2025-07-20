FROM ubuntu:24.04

# Install mise via apt
RUN apt-get update && \
    apt-get install -y \
    gpg \
    sudo \
    curl \
    wget \
    git && \
    wget -qO - https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | tee /etc/apt/keyrings/mise-archive-keyring.gpg 1> /dev/null && \
    echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=amd64] https://mise.jdx.dev/deb stable main" | tee /etc/apt/sources.list.d/mise.list && \
    apt-get update && \
    apt-get install -y mise && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create user - check if UID 1000 exists, if so delete it first
RUN if id -u 1000 >/dev/null 2>&1; then userdel -r $(id -un 1000); fi && \
    useradd -m -u 1000 -s /bin/bash fx && \
    echo "fx ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to the fx user
USER fx
WORKDIR /home/fx

# Setup mise for the fx user
RUN echo 'eval "$(mise activate bash)"' >> ~/.bashrc