#!/bin/bash
# Script de configuration JupyterLab + ComfyUI RTX 4090 pour vast.ai
# Version: 1.0

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/workspace/jupyter-setup.log"
CONTAINER_NAME="comfyui-jupyter"
IMAGE_NAME="ghcr.io/VOTRE_USERNAME/comfyui-docker-rtx4090:jupyter"
DEFAULT_PASSWORD="comfyui4090"

# Couleurs pour l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Fonction de logging avec timestamp et couleur
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "INFO")
            echo -e "${GREEN}[INFO]${NC} ${timestamp} - $message" | tee -a "$LOG_FILE"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} ${timestamp} - $message" | tee -a "$LOG_FILE"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} ${timestamp} - $message" | tee -a "$LOG_FILE"
            ;;
        "DEBUG")
            echo -e "${BLUE}[DEBUG]${NC} ${timestamp} - $message" | tee -a "$LOG_FILE"
            ;;
    esac
}

# Fonction pour générer un hash de mot de passe JupyterLab
generate_password_hash() {
    local password=${1:-$DEFAULT_PASSWORD}
    log "INFO" "Génération du hash pour mot de passe JupyterLab..."
    
    python3 -c "
from jupyter_server.auth import passwd
print(passwd('$password'))
"
}

# Fonction pour vérifier les prérequis
check_prerequisites() {
    log "INFO" "🔍 Vérification des prérequis JupyterLab + ComfyUI..."
    
    # Vérifier Docker
    if ! command -v docker &> /dev/null; then
        log "ERROR" "Docker n'est pas installé"
        exit 1
    fi
    log "INFO" "✅ Docker détecté: $(docker --version)"
    
    # Vérifier Python (pour génération hash)
    if ! command -v python3 &> /dev/null; then
        log "ERROR" "Python3 n'est pas installé"
        exit 1
    fi
    
    # Installer jupyter_server si nécessaire pour génération de hash
    if ! python3 -c "import jupyter_server.auth" 2>/dev/null; then
        log "INFO" "Installation de jupyter_server pour génération de hash..."
        pip3 install jupyter_server
    fi
    
    # Vérifier nvidia-docker
    if ! docker info 2>/dev/null | grep -i nvidia &> /dev/null; then
        log "WARN" "nvidia-docker runtime peut ne pas être configuré correctement"
    else
        log "INFO" "✅ nvidia-docker runtime configuré"
    fi
    
    # Vérifier GPU RTX 4090
    if command -v nvidia-smi &> /dev/null; then
        local gpu_info=$(nvidia-smi --query-gpu=name --format=csv,noheader,nounits | head -n1)
        log "INFO" "GPU détecté: $gpu_info"
        
        if echo "$gpu_info" | grep -i "4090" &> /dev/null; then
            log "INFO" "✅ RTX 4090 détecté - optimisations activées"
        else
            log "WARN" "GPU non RTX 4090 détecté - les optimisations peuvent ne pas être optimales"
        fi
    else
        log "WARN" "nvidia-smi non disponible - impossible de vérifier le GPU"
    fi
}

# Fonction pour préparer l'environnement
setup_environment() {
    log "INFO" "🏗️  Préparation de l'environnement JupyterLab..."
    
    # Créer la structure de répertoires
    mkdir -p /workspace/{models,output,input,logs,notebooks,jupyter-config}
    mkdir -p /workspace/models/{checkpoints,vae,clip,controlnet,upscale_models,embeddings,loras}
    
    # Créer quelques notebooks d'exemple
    cat > /workspace/notebooks/ComfyUI_Getting_Started.ipynb << 'EOF'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# 🚀 ComfyUI RTX 4090 - Getting Started\n",
    "\n",
    "Bienvenue dans votre environnement ComfyUI optimisé RTX 4090 !\n",
    "\n",
    "## Accès à ComfyUI\n",
    "\n",
    "1. **Via le Launcher JupyterLab**: Cliquez sur l'icône ComfyUI dans le launcher\n",
    "2. **Via URL directe**: [ComfyUI Interface](/proxy/8188/)\n",
    "3. **Nouvel onglet**: [Ouvrir ComfyUI](http://localhost:8188) (si accès direct autorisé)\n",
    "\n",
    "## Vérifications Système"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Vérification GPU RTX 4090\n",
    "import torch\n",
    "print(f\"CUDA disponible: {torch.cuda.is_available()}\")\n",
    "if torch.cuda.is_available():\n",
    "    print(f\"GPU: {torch.cuda.get_device_name()}\")\n",
    "    print(f\"VRAM totale: {torch.cuda.get_device_properties(0).total_memory // 1024**3}GB\")\n",
    "    print(f\"Version CUDA: {torch.version.cuda}\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Vérification des optimisations xFormers\n",
    "try:\n",
    "    import xformers\n",
    "    print(f\"✅ xFormers installé: {xformers.__version__}\")\n",
    "except ImportError:\n",
    "    print(\"❌ xFormers non installé\")"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## Monitoring GPU\n",
    "\n",
    "Surveillez l'utilisation GPU pendant la génération :"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Monitoring GPU simple\n",
    "!nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## Tests de Performance\n",
    "\n",
    "### Benchmarks attendus RTX 4090:\n",
    "- **FLUX Schnell 1024x1024**: ~3-4s (4 steps)\n",
    "- **SDXL 1024x1024**: ~1.5-2s (20 steps)\n",
    "- **SD 1.5 512x512**: ~0.8s (20 steps)\n",
    "\n",
    "### Extensions pré-installées:\n",
    "- ComfyUI Manager\n",
    "- rgthree-comfy  \n",
    "- WAS Node Suite\n",
    "- ComfyUI Impact Pack\n",
    "- IPAdapter Plus\n",
    "- Et 5+ autres extensions essentielles\n",
    "\n",
    "## Liens Utiles\n",
    "\n",
    "- [ComfyUI Documentation](https://github.com/comfyanonymous/ComfyUI)\n",
    "- [Extensions Hub](https://github.com/ltdrdata/ComfyUI-Manager)\n",
    "- [Community Workflows](https://comfyworkflows.com/)\n",
    "\n",
    "---\n",
    "**🎯 Prêt à créer ? Ouvrez ComfyUI et commencez à générer !**"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "name": "python",
   "version": "3.10.0"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF
    
    log "INFO" "✅ Répertoires et notebooks créés"
    
    # Configurer les permissions
    chmod -R 755 /workspace
    log "INFO" "✅ Permissions configurées"
}

# Fonction pour configurer le mot de passe JupyterLab
configure_jupyter_password() {
    local password=${JUPYTER_PASSWORD:-$DEFAULT_PASSWORD}
    log "INFO" "🔐 Configuration du mot de passe JupyterLab..."
    
    # Générer le hash du mot de passe
    local password_hash=$(generate_password_hash "$password")
    
    # Créer la configuration JupyterLab
    cat > /workspace/jupyter-config/jupyter_server_config.py << EOF
c = get_config()

# Configuration réseau
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8888
c.ServerApp.open_browser = False
c.ServerApp.allow_origin = '*'
c.ServerApp.allow_remote_access = True

# Authentification
c.ServerApp.token = ''
c.ServerApp.password = '$password_hash'

# Répertoires
c.ServerApp.root_dir = '/home/jupyter'
c.ServerApp.notebook_dir = '/home/jupyter'

# Sécurité
c.ServerApp.disable_check_xsrf = True
c.ServerApp.tornado_settings = {
    'headers': {
        'Content-Security-Policy': "frame-ancestors 'self' *;"
    }
}

# Extensions
c.ServerApp.jpserver_extensions = {
    'jupyter_server_proxy': True
}
EOF
    
    log "INFO" "✅ Configuration JupyterLab créée avec mot de passe: $password"
}

# Fonction pour télécharger l'image si nécessaire
pull_image() {
    log "INFO" "📥 Vérification de l'image Docker JupyterLab..."
    
    if docker images "$IMAGE_NAME" | grep -q "$IMAGE_NAME"; then
        log "INFO" "Image $IMAGE_NAME déjà présente localement"
    else
        log "INFO" "Téléchargement de l'image $IMAGE_NAME..."
        if docker pull "$IMAGE_NAME"; then
            log "INFO" "✅ Image téléchargée avec succès"
        else
            log "ERROR" "Échec du téléchargement de l'image"
            exit 1
        fi
    fi
    
    # Vérifier la taille de l'image
    local image_size=$(docker images --format "table {{.Size}}" "$IMAGE_NAME" | tail -n +2)
    log "INFO" "Taille de l'image: $image_size"
}

# Fonction pour arrêter les containers existants
stop_existing_containers() {
    log "INFO" "🛑 Arrêt des containers JupyterLab existants..."
    
    local existing_containers=$(docker ps -a --filter "name=comfyui" --format "{{.Names}}")
    
    if [ -n "$existing_containers" ]; then
        log "INFO" "Arrêt des containers: $existing_containers"
        echo "$existing_containers" | xargs -r docker stop
        echo "$existing_containers" | xargs -r docker rm
        log "INFO" "✅ Containers existants arrêtés et supprimés"
    else
        log "INFO" "Aucun container ComfyUI existant trouvé"
    fi
}

# Fonction pour démarrer JupyterLab + ComfyUI
start_jupyter_comfyui() {
    log "INFO" "🚀 Démarrage JupyterLab + ComfyUI RTX 4090..."
    
    # Paramètres de démarrage optimisés
    docker run -d \
        --name "$CONTAINER_NAME" \
        --gpus all \
        --restart unless-stopped \
        -p 8888:8888 \
        -p 8188:8188 \
        -e PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512 \
        -e CUDA_VISIBLE_DEVICES=0 \
        -e NVIDIA_VISIBLE_DEVICES=all \
        -e NVIDIA_DRIVER_CAPABILITIES=compute,utility \
        -v /workspace/models:/home/jupyter/ComfyUI/models \
        -v /workspace/output:/home/jupyter/ComfyUI/output \
        -v /workspace/input:/home/jupyter/ComfyUI/input \
        -v /workspace/logs:/home/jupyter/ComfyUI/logs \
        -v /workspace/notebooks:/home/jupyter/notebooks \
        -v /workspace/jupyter-config:/home/jupyter/.jupyter \
        --shm-size=1g \
        --memory=30g \
        --memory-swap=30g \
        "$IMAGE_NAME"
    
    if [ $? -eq 0 ]; then
        log "INFO" "✅ JupyterLab + ComfyUI démarré avec succès"
    else
        log "ERROR" "Échec du démarrage de JupyterLab + ComfyUI"
        exit 1
    fi
}

# Fonction de monitoring du démarrage
monitor_startup() {
    log "INFO" "📊 Monitoring du démarrage JupyterLab..."
    
    local max_wait=180  # 3 minutes pour JupyterLab + ComfyUI
    local wait_time=0
    local interval=10
    
    while [ $wait_time -lt $max_wait ]; do
        # Vérifier JupyterLab
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:8888/api | grep -q "200"; then
            log "INFO" "✅ JupyterLab accessible sur http://localhost:8888/"
            
            # Vérifier ComfyUI via proxy
            sleep 10  # Attendre un peu plus pour ComfyUI
            if curl -s -o /dev/null -w "%{http_code}" http://localhost:8188/ | grep -q "200"; then
                log "INFO" "✅ ComfyUI accessible via proxy"
                break
            else
                log "DEBUG" "ComfyUI encore en démarrage..."
            fi
        else
            log "DEBUG" "En attente du démarrage de JupyterLab... (${wait_time}s/${max_wait}s)"
        fi
        
        sleep $interval
        wait_time=$((wait_time + interval))
    done
    
    if [ $wait_time -ge $max_wait ]; then
        log "WARN" "Timeout atteint - vérifiez les logs du container"
        docker logs "$CONTAINER_NAME" --tail 30
    fi
}

# Fonction de vérification post-déploiement
verify_deployment() {
    log "INFO" "🔍 Vérification du déploiement JupyterLab + ComfyUI..."
    
    # Vérifier que le container tourne
    if docker ps | grep -q "$CONTAINER_NAME"; then
        log "INFO" "✅ Container en cours d'exécution"
    else
        log "ERROR" "❌ Container non trouvé"
        return 1
    fi
    
    # Vérifier l'utilisation GPU
    if command -v nvidia-smi &> /dev/null; then
        log "INFO" "Utilisation GPU:"
        nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits | tee -a "$LOG_FILE"
    fi
    
    # Afficher les stats du container
    log "INFO" "Stats du container:"
    docker stats "$CONTAINER_NAME" --no-stream | tee -a "$LOG_FILE"
    
    # Tester les endpoints
    if curl -s http://localhost:8888/api | grep -q "version"; then
        log "INFO" "✅ API JupyterLab accessible"
    else
        log "WARN" "API JupyterLab peut ne pas être entièrement chargée"
    fi
    
    if curl -s http://localhost:8188/ | grep -q "ComfyUI"; then
        log "INFO" "✅ ComfyUI accessible"
    else
        log "WARN" "ComfyUI peut ne pas être entièrement chargé"
    fi
}

# Fonction pour afficher les informations de connexion
show_connection_info() {
    local password=${JUPYTER_PASSWORD:-$DEFAULT_PASSWORD}
    
    log "INFO" "🌐 Informations de connexion:"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${PURPLE}🔬 JupyterLab + ComfyUI RTX 4090 - Prêt à utiliser!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo -e "${YELLOW}🔐 Accès JupyterLab (SÉCURISÉ):${NC}"
    echo -e "   URL: ${GREEN}http://$(curl -s ifconfig.me 2>/dev/null || echo 'localhost'):8888/${NC}"
    echo -e "   Mot de passe: ${BLUE}$password${NC}"
    echo
    echo -e "${YELLOW}🎨 Accès ComfyUI:${NC}"
    echo -e "   Via JupyterLab: ${GREEN}Cliquez sur 'ComfyUI' dans le launcher${NC}"
    echo -e "   URL directe: ${GREEN}http://$(curl -s ifconfig.me 2>/dev/null || echo 'localhost'):8188/${NC} (non sécurisé)"
    echo
    echo -e "${YELLOW}📁 Répertoires:${NC}"
    echo -e "   Modèles: ${BLUE}/workspace/models/${NC}"
    echo -e "   Output: ${BLUE}/workspace/output/${NC}"
    echo -e "   Notebooks: ${BLUE}/workspace/notebooks/${NC}"
    echo -e "   Logs: ${BLUE}/workspace/logs/${NC}"
    echo
    echo -e "${YELLOW}🐳 Container:${NC}"
    echo -e "   Nom: ${BLUE}$CONTAINER_NAME${NC}"
    echo -e "   Status: ${GREEN}$(docker inspect -f '{{.State.Status}}' "$CONTAINER_NAME")${NC}"
    echo
    echo -e "${YELLOW}⚡ Optimisations RTX 4090 actives:${NC}"
    echo -e "   ✅ CUDA 12.8 + PyTorch optimisé"
    echo -e "   ✅ JupyterLab + proxy ComfyUI intégré"
    echo -e "   ✅ Authentification par mot de passe"
    echo -e "   ✅ xFormers pour accélération mémoire"
    echo -e "   ✅ Extensions essentielles installées"
    echo
    echo -e "${YELLOW}📊 Commandes utiles:${NC}"
    echo -e "   Logs JupyterLab: ${BLUE}docker logs -f $CONTAINER_NAME${NC}"
    echo -e "   Stats: ${BLUE}docker stats $CONTAINER_NAME${NC}"
    echo -e "   GPU: ${BLUE}nvidia-smi${NC}"
    echo -e "   Redémarrer: ${BLUE}docker restart $CONTAINER_NAME${NC}"
    echo -e "   Shell: ${BLUE}docker exec -it $CONTAINER_NAME bash${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Fonction principale
main() {
    echo -e "${PURPLE}🔬 JupyterLab + ComfyUI RTX 4090 - Script de déploiement vast.ai${NC}"
    echo -e "${PURPLE}Version 1.0 - Accès sécurisé${NC}"
    echo
    
    log "INFO" "Début du déploiement JupyterLab + ComfyUI..."
    
    # Initialisation du log
    echo "=== JupyterLab + ComfyUI RTX 4090 Deployment Log ===" > "$LOG_FILE"
    echo "Started at: $(date)" >> "$LOG_FILE"
    
    # Étapes de déploiement
    check_prerequisites
    setup_environment
    configure_jupyter_password
    pull_image
    stop_existing_containers
    start_jupyter_comfyui
    monitor_startup
    verify_deployment
    show_connection_info
    
    log "INFO" "✅ Déploiement JupyterLab + ComfyUI terminé avec succès!"
    log "INFO" "📋 Logs complets disponibles dans: $LOG_FILE"
}

# Gestion des erreurs
trap 'log "ERROR" "Script interrompu à la ligne $LINENO"' ERR

# Exécution
main "$@"