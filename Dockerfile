# ComfyUI Docker optimisé pour RTX 4090
# Base: CUDA 12.8 pour support Ada Lovelace complet
# Build forcé pour déploiement initial GHCR
FROM nvidia/cuda:12.8-cudnn9-devel-ubuntu22.04

LABEL maintainer="ComfyUI-RTX4090-Optimized"
LABEL version="1.0"
LABEL description="ComfyUI optimisé pour RTX 4090 avec extensions essentielles"

# Éviter les prompts interactifs
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Variables d'environnement pour optimisations RTX 4090
ENV PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
ENV CUDA_VISIBLE_DEVICES=0
ENV TORCH_CUDA_ARCH_LIST="8.9"
ENV FORCE_CUDA=1
ENV MAX_JOBS=8

# Installation des dépendances système
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    git \
    wget \
    curl \
    unzip \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libgoogle-perftools4 \
    libtcmalloc-minimal4 \
    ffmpeg \
    libsndfile1 \
    && rm -rf /var/lib/apt/lists/*

# Configurer Python
RUN ln -sf /usr/bin/python3 /usr/bin/python
RUN pip3 install --upgrade pip setuptools wheel

# Installer PyTorch optimisé pour RTX 4090
RUN pip3 install torch==2.5.1+cu124 torchvision==0.20.1+cu124 torchaudio==2.5.1+cu124 \
    --index-url https://download.pytorch.org/whl/cu124

# Installer xFormers pour optimisations mémoire
RUN pip3 install xformers==0.0.28.post3

# Créer utilisateur non-root
RUN useradd -m -s /bin/bash comfyui
USER comfyui
WORKDIR /home/comfyui

# Cloner ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git
WORKDIR /home/comfyui/ComfyUI

# Installer les dépendances ComfyUI
RUN pip3 install --user -r requirements.txt

# Installer les dépendances supplémentaires pour RTX 4090
RUN pip3 install --user \
    accelerate \
    transformers \
    diffusers \
    compel \
    opencv-python \
    pillow-simd \
    numba \
    scipy \
    einops \
    timm \
    kornia \
    spandrel

# Installation des extensions essentielles
WORKDIR /home/comfyui/ComfyUI/custom_nodes

# ComfyUI Manager - Gestion des nodes
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git

# rgthree-comfy - Workflow amélioré
RUN git clone https://github.com/rgthree/rgthree-comfy.git
RUN cd rgthree-comfy && pip3 install --user -r requirements.txt

# WAS Node Suite - Suite complète d'outils
RUN git clone https://github.com/WASasquatch/was-node-suite-comfyui.git
RUN cd was-node-suite-comfyui && pip3 install --user -r requirements.txt

# ComfyUI Impact Pack - Enhancement facial
RUN git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git
RUN cd ComfyUI-Impact-Pack && pip3 install --user -r requirements.txt

# IPAdapter Plus - Transfert de style
RUN git clone https://github.com/cubiq/ComfyUI_IPAdapter_plus.git

# ComfyUI KJNodes - Utilitaires pratiques
RUN git clone https://github.com/kijai/ComfyUI-KJNodes.git
RUN cd ComfyUI-KJNodes && pip3 install --user -r requirements.txt

# Custom Scripts - Scripts personnalisés
RUN git clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git

# cg-use-everywhere - Connexions sans fils
RUN git clone https://github.com/chrisgoringe/cg-use-everywhere.git

# ComfyUI Essentials - QOL améliorations
RUN git clone https://github.com/cubiq/ComfyUI_essentials.git

# Ultimate SD Upscale - Upscaling avancé
RUN git clone https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git

# Retour au répertoire ComfyUI
WORKDIR /home/comfyui/ComfyUI

# Créer les répertoires pour les modèles
RUN mkdir -p models/checkpoints models/vae models/clip models/controlnet models/upscale_models

# Script de sanity check pour les optimisations RTX 4090
RUN echo '#!/bin/bash\n\
echo "🚀 Vérification des optimisations RTX 4090..."\n\
python3 -c "import torch; print(f\"CUDA disponible: {torch.cuda.is_available()}\")"\n\
python3 -c "import torch; print(f\"Version CUDA: {torch.version.cuda}\")"\n\
python3 -c "import torch; print(f\"GPU détecté: {torch.cuda.get_device_name() if torch.cuda.is_available() else \"Aucun\"}\")"\n\
python3 -c "import torch; print(f\"VRAM disponible: {torch.cuda.get_device_properties(0).total_memory // 1024**3}GB\" if torch.cuda.is_available() else \"N/A\")"\n\
python3 -c "try: import xformers; print(\"✅ xFormers installé\"); except: print(\"❌ xFormers manquant\")"\n\
echo "🔧 Configuration système prête pour RTX 4090"\n\
' > /home/comfyui/ComfyUI/check_setup.sh && chmod +x /home/comfyui/ComfyUI/check_setup.sh

# Script de lancement optimisé
RUN echo '#!/bin/bash\n\
echo "🚀 Démarrage ComfyUI optimisé RTX 4090..."\n\
\n\
# Vérifications système\n\
./check_setup.sh\n\
\n\
# Optimisations mémoire\n\
export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512\n\
export CUDA_VISIBLE_DEVICES=0\n\
\n\
# Démarrage avec paramètres optimisés RTX 4090\n\
python3 main.py \\\n\
    --listen 0.0.0.0 \\\n\
    --port 8188 \\\n\
    --use-pytorch-cross-attention \\\n\
    --cuda-malloc \\\n\
    --use-stream \\\n\
    --highvram \\\n\
    --fast \\\n\
    --force-fp16 \\\n\
    --disable-nan-check \\\n\
    "$@"\n\
' > /home/comfyui/ComfyUI/start_comfyui.sh && chmod +x /home/comfyui/ComfyUI/start_comfyui.sh

# Configuration du logging avancé
RUN echo '#!/bin/bash\n\
LOG_DIR="/home/comfyui/ComfyUI/logs"\n\
mkdir -p $LOG_DIR\n\
\n\
# Fonction de logging avec timestamp\n\
log() {\n\
    echo "[$(date '\''+%Y-%m-%d %H:%M:%S'\'')] $1" | tee -a $LOG_DIR/comfyui.log\n\
}\n\
\n\
# Monitoring GPU en arrière-plan\n\
monitor_gpu() {\n\
    while true; do\n\
        if command -v nvidia-smi >/dev/null 2>&1; then\n\
            echo "[$(date '\''+%Y-%m-%d %H:%M:%S'\'')] GPU Status:" >> $LOG_DIR/gpu_monitor.log\n\
            nvidia-smi --query-gpu=name,memory.used,memory.total,temperature.gpu,utilization.gpu --format=csv,noheader,nounits >> $LOG_DIR/gpu_monitor.log\n\
            echo "---" >> $LOG_DIR/gpu_monitor.log\n\
        fi\n\
        sleep 30\n\
    done &\n\
}\n\
\n\
# Démarrage du monitoring\n\
log "🔍 Démarrage du monitoring GPU..."\n\
monitor_gpu\n\
\n\
# Démarrage ComfyUI avec logging\n\
log "🚀 Lancement ComfyUI..."\n\
./start_comfyui.sh 2>&1 | tee -a $LOG_DIR/comfyui.log\n\
' > /home/comfyui/ComfyUI/start_with_logging.sh && chmod +x /home/comfyui/ComfyUI/start_with_logging.sh

# Exposition du port
EXPOSE 8188

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8188/ || exit 1

# Commande par défaut
CMD ["./start_with_logging.sh"]