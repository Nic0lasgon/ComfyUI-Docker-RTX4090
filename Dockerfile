# ComfyUI Docker optimisé pour RTX 4090
# Basé sur mmartial/ComfyUI-Nvidia-Docker pour stabilité
FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04

ARG BASE_DOCKER_FROM=nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04
ARG COMFYUI_NVIDIA_DOCKER_VERSION="rtx4090-optimized"

##### Base System Setup
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y --fix-missing\
  && apt-get install -y \
    apt-utils \
    locales \
    ca-certificates \
    && apt-get upgrade -y \
    && apt-get clean

# UTF-8 Locale
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG=en_US.utf8
ENV LC_ALL=C

# Install needed packages
RUN apt-get update -y --fix-missing \
  && apt-get upgrade -y \
  && apt-get install -y \
    build-essential \
    python3-dev \
    unzip \
    wget \
    zip \
    zlib1g \
    zlib1g-dev \
    gnupg \
    rsync \
    python3-pip \
    python3-venv \
    git \
    sudo \
    libglib2.0-0 \
    socat \
    curl \
  && apt-get clean

# Add libEGL ICD loaders and Vulkan support  
RUN apt install -y libglvnd0 libglvnd-dev libegl1-mesa-dev libvulkan1 libvulkan-dev ffmpeg \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir -p /usr/share/glvnd/egl_vendor.d \
  && echo '{"file_format_version":"1.0.0","ICD":{"library_path":"libEGL_nvidia.so.0"}}' > /usr/share/glvnd/egl_vendor.d/10_nvidia.json \
  && mkdir -p /usr/share/vulkan/icd.d \
  && echo '{"file_format_version":"1.0.0","ICD":{"library_path":"libGLX_nvidia.so.0","api_version":"1.3"}}' > /usr/share/vulkan/icd.d/nvidia_icd.json
ENV MESA_D3D12_DEFAULT_ADAPTER_NAME="NVIDIA"

# Build info
ENV BUILD_FILE="/etc/image_base.txt"
RUN echo "DOCKER_FROM: ${BASE_DOCKER_FROM}" | tee ${BUILD_FILE}
RUN echo "CUDNN: ${NV_CUDNN_PACKAGE_NAME} (${NV_CUDNN_VERSION})" | tee -a ${BUILD_FILE}

##### User Setup (following mmartial pattern)
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Create groups and users
RUN groupadd -g 1024 comfy \ 
    && groupadd -g 1025 comfytoo

RUN useradd -u 1024 -d /home/comfy -g comfy -s /bin/bash -m comfy \
    && usermod -G users comfy \
    && adduser comfy sudo
RUN useradd -u 1025 -d /home/comfytoo -g comfytoo -s /bin/bash -m comfytoo \
    && usermod -G users comfytoo \
    && adduser comfytoo sudo

ENV COMFYUSER_DIR="/comfy"
RUN mkdir -p ${COMFYUSER_DIR}
RUN it="/etc/comfyuser_dir"; echo ${COMFYUSER_DIR} > $it && chmod 555 $it

# NVIDIA Environment
ENV NVIDIA_DRIVER_CAPABILITIES="all"
ENV NVIDIA_VISIBLE_DEVICES=all

# RTX 4090 Optimizations
ENV PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
ENV TORCH_CUDA_ARCH_LIST="8.9"
ENV FORCE_CUDA=1

# Expose port
EXPOSE 8188

# Labels
LABEL comfyui-nvidia-docker-build-from="rtx4090-optimized"
LABEL comfyui-nvidia-docker-build=${COMFYUI_NVIDIA_DOCKER_VERSION}
RUN echo "COMFYUI_NVIDIA_DOCKER_VERSION: ${COMFYUI_NVIDIA_DOCKER_VERSION}" | tee -a ${BUILD_FILE}

# Create init script as root before switching user  
RUN echo '#!/bin/bash\necho "🚀 ComfyUI RTX 4090 Container Ready"\necho "ComfyUI will be installed at first run"\nexec "$@"' > /comfyui-nvidia_init.bash && chmod +x /comfyui-nvidia_init.bash

# Start as comfytoo user
USER comfytoo

ENTRYPOINT [ "/comfyui-nvidia_init.bash" ]
CMD ["python3", "-c", "print('Container ready. Mount volumes and run with proper environment variables.')"]