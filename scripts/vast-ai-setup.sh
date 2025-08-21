#!/bin/bash
# Script de déploiement ComfyUI RTX 4090 optimisé pour vast.ai
# Version: 1.0

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/workspace/setup.log"
COMFYUI_DIR="/workspace/ComfyUI"
IMAGE_NAME="ghcr.io/VOTRE_USERNAME/comfyui-docker-rtx4090:latest"

# Couleurs pour l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Fonction pour vérifier les prérequis
check_prerequisites() {
    log "INFO" "🔍 Vérification des prérequis système..."
    
    # Vérifier Docker
    if ! command -v docker &> /dev/null; then
        log "ERROR" "Docker n'est pas installé"
        exit 1
    fi
    log "INFO" "✅ Docker détecté: $(docker --version)"
    
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
        
        # Afficher les stats GPU
        log "INFO" "Stats GPU:"
        nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv | tee -a "$LOG_FILE"
    else
        log "WARN" "nvidia-smi non disponible - impossible de vérifier le GPU"
    fi
}

# Fonction pour préparer l'environnement
setup_environment() {
    log "INFO" "🏗️  Préparation de l'environnement..."
    
    # Créer la structure de répertoires
    mkdir -p /workspace/{models,output,input,logs,cache}
    mkdir -p /workspace/models/{checkpoints,vae,clip,controlnet,upscale_models}
    
    log "INFO" "✅ Répertoires créés"
    
    # Configurer les permissions
    chmod -R 755 /workspace
    log "INFO" "✅ Permissions configurées"
}

# Fonction pour télécharger l'image si nécessaire
pull_image() {
    log "INFO" "📥 Vérification de l'image Docker..."
    
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
    log "INFO" "🛑 Arrêt des containers ComfyUI existants..."
    
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

# Fonction pour démarrer ComfyUI
start_comfyui() {
    log "INFO" "🚀 Démarrage de ComfyUI optimisé RTX 4090..."
    
    # Paramètres de démarrage optimisés
    docker run -d \
        --name comfyui-vast \
        --gpus all \
        --restart unless-stopped \
        -p 8188:8188 \
        -e PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512 \
        -e CUDA_VISIBLE_DEVICES=0 \
        -e NVIDIA_VISIBLE_DEVICES=all \
        -e NVIDIA_DRIVER_CAPABILITIES=compute,utility \
        -v /workspace/models:/home/comfyui/ComfyUI/models \
        -v /workspace/output:/home/comfyui/ComfyUI/output \
        -v /workspace/input:/home/comfyui/ComfyUI/input \
        -v /workspace/logs:/home/comfyui/ComfyUI/logs \
        -v /workspace/cache:/home/comfyui/.cache \
        --shm-size=1g \
        --memory=30g \
        --memory-swap=30g \
        "$IMAGE_NAME"
    
    if [ $? -eq 0 ]; then
        log "INFO" "✅ ComfyUI démarré avec succès"
    else
        log "ERROR" "Échec du démarrage de ComfyUI"
        exit 1
    fi
}

# Fonction de monitoring du démarrage
monitor_startup() {
    log "INFO" "📊 Monitoring du démarrage..."
    
    local max_wait=120  # 2 minutes
    local wait_time=0
    local interval=5
    
    while [ $wait_time -lt $max_wait ]; do
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:8188/ | grep -q "200"; then
            log "INFO" "✅ ComfyUI est accessible sur http://localhost:8188/"
            break
        else
            log "DEBUG" "En attente du démarrage de ComfyUI... (${wait_time}s/${max_wait}s)"
            sleep $interval
            wait_time=$((wait_time + interval))
        fi
    done
    
    if [ $wait_time -ge $max_wait ]; then
        log "WARN" "Timeout atteint - vérifiez les logs du container"
        docker logs comfyui-vast --tail 20
    fi
}

# Fonction de vérification post-déploiement
verify_deployment() {
    log "INFO" "🔍 Vérification du déploiement..."
    
    # Vérifier que le container tourne
    if docker ps | grep -q comfyui-vast; then
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
    docker stats comfyui-vast --no-stream | tee -a "$LOG_FILE"
    
    # Tester l'endpoint
    if curl -s http://localhost:8188/ | grep -q "ComfyUI"; then
        log "INFO" "✅ Interface web accessible"
    else
        log "WARN" "Interface web peut ne pas être entièrement chargée"
    fi
}

# Fonction pour afficher les informations de connexion
show_connection_info() {
    log "INFO" "🌐 Informations de connexion:"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🚀 ComfyUI RTX 4090 Optimisé - Prêt à utiliser!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo -e "${YELLOW}🔗 URL d'accès:${NC}"
    echo -e "   Local: ${GREEN}http://localhost:8188/${NC}"
    echo -e "   Public: ${GREEN}http://$(curl -s ifconfig.me):8188/${NC}"
    echo
    echo -e "${YELLOW}📁 Répertoires:${NC}"
    echo -e "   Modèles: ${BLUE}/workspace/models/${NC}"
    echo -e "   Output: ${BLUE}/workspace/output/${NC}"
    echo -e "   Input: ${BLUE}/workspace/input/${NC}"
    echo -e "   Logs: ${BLUE}/workspace/logs/${NC}"
    echo
    echo -e "${YELLOW}🐳 Container:${NC}"
    echo -e "   Nom: ${BLUE}comfyui-vast${NC}"
    echo -e "   Status: ${GREEN}$(docker inspect -f '{{.State.Status}}' comfyui-vast)${NC}"
    echo
    echo -e "${YELLOW}⚡ Optimisations RTX 4090 actives:${NC}"
    echo -e "   ✅ CUDA 12.8 + PyTorch optimisé"
    echo -e "   ✅ xFormers pour accélération mémoire"
    echo -e "   ✅ Extensions essentielles installées"
    echo -e "   ✅ Monitoring GPU intégré"
    echo
    echo -e "${YELLOW}📊 Commandes utiles:${NC}"
    echo -e "   Logs: ${BLUE}docker logs -f comfyui-vast${NC}"
    echo -e "   Stats: ${BLUE}docker stats comfyui-vast${NC}"
    echo -e "   GPU: ${BLUE}nvidia-smi${NC}"
    echo -e "   Redémarrer: ${BLUE}docker restart comfyui-vast${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Fonction principale
main() {
    echo -e "${BLUE}🚀 ComfyUI RTX 4090 - Script de déploiement vast.ai${NC}"
    echo -e "${BLUE}Version 1.0${NC}"
    echo
    
    log "INFO" "Début du déploiement..."
    
    # Initialisation du log
    echo "=== ComfyUI RTX 4090 Deployment Log ===" > "$LOG_FILE"
    echo "Started at: $(date)" >> "$LOG_FILE"
    
    # Étapes de déploiement
    check_prerequisites
    setup_environment
    pull_image
    stop_existing_containers
    start_comfyui
    monitor_startup
    verify_deployment
    show_connection_info
    
    log "INFO" "✅ Déploiement terminé avec succès!"
    log "INFO" "📋 Logs complets disponibles dans: $LOG_FILE"
}

# Gestion des erreurs
trap 'log "ERROR" "Script interrompu à la ligne $LINENO"' ERR

# Exécution
main "$@"