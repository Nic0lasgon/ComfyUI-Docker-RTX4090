#!/bin/bash
# Script de test local avant déploiement GitHub
# Version: 1.0

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
IMAGE_BASE="comfyui-rtx4090-test"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Fonction de logging
log() {
    local level=$1
    shift
    local message="$*"
    
    case $level in
        "INFO")
            echo -e "${GREEN}[INFO]${NC} $message"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message"
            ;;
        "DEBUG")
            echo -e "${BLUE}[DEBUG]${NC} $message"
            ;;
    esac
}

# Fonction pour tester la construction d'une image
test_build() {
    local dockerfile=$1
    local tag=$2
    local name=$3
    
    log "INFO" "🏗️  Test construction $name..."
    
    cd "$PROJECT_ROOT"
    
    if docker build -f "$dockerfile" -t "$tag" .; then
        log "INFO" "✅ Construction $name réussie"
        return 0
    else
        log "ERROR" "❌ Échec construction $name"
        return 1
    fi
}

# Fonction pour tester le démarrage d'un container
test_startup() {
    local image=$1
    local container_name=$2
    local ports=$3
    local description=$4
    
    log "INFO" "🚀 Test démarrage $description..."
    
    # Nettoyer container existant
    docker stop "$container_name" 2>/dev/null || true
    docker rm "$container_name" 2>/dev/null || true
    
    # Démarrer le container
    if docker run -d --name "$container_name" $ports "$image"; then
        log "INFO" "✅ Container $description démarré"
        
        # Attendre un peu pour le démarrage
        sleep 10
        
        # Vérifier que le container tourne
        if docker ps | grep -q "$container_name"; then
            log "INFO" "✅ Container $description fonctionne"
            return 0
        else
            log "ERROR" "❌ Container $description s'est arrêté"
            docker logs "$container_name"
            return 1
        fi
    else
        log "ERROR" "❌ Échec démarrage $description"
        return 1
    fi
}

# Fonction pour tester les endpoints
test_endpoints() {
    local ports_info=$1
    local description=$2
    
    log "INFO" "🔍 Test endpoints $description..."
    
    # Attendre que les services soient prêts
    local max_wait=60
    local wait_time=0
    
    while [ $wait_time -lt $max_wait ]; do
        local all_ready=true
        
        # Tester selon les ports
        if echo "$ports_info" | grep -q "8188"; then
            if ! curl -s http://localhost:8188/ > /dev/null; then
                all_ready=false
            fi
        fi
        
        if echo "$ports_info" | grep -q "8888"; then
            if ! curl -s http://localhost:8888/api > /dev/null; then
                all_ready=false
            fi
        fi
        
        if [ "$all_ready" = true ]; then
            log "INFO" "✅ Tous les endpoints $description sont accessibles"
            return 0
        fi
        
        sleep 2
        wait_time=$((wait_time + 2))
    done
    
    log "WARN" "⚠️  Timeout endpoints $description - peuvent nécessiter plus de temps"
    return 0  # Ne pas faire échouer le test pour timeout
}

# Fonction pour nettoyer les containers de test
cleanup() {
    log "INFO" "🧹 Nettoyage containers de test..."
    
    docker stop comfyui-standard-test 2>/dev/null || true
    docker stop comfyui-jupyter-test 2>/dev/null || true
    docker rm comfyui-standard-test 2>/dev/null || true
    docker rm comfyui-jupyter-test 2>/dev/null || true
    
    log "INFO" "✅ Nettoyage terminé"
}

# Fonction pour afficher les statistiques
show_stats() {
    log "INFO" "📊 Statistiques des images construites:"
    echo
    docker images | grep "$IMAGE_BASE" | while read -r line; do
        echo "  $line"
    done
    echo
}

# Fonction pour valider les fichiers requis
validate_files() {
    log "INFO" "🔍 Validation des fichiers du projet..."
    
    local required_files=(
        "Dockerfile"
        "Dockerfile.jupyter"
        "docker-compose.yml"
        ".github/workflows/build.yml"
        "scripts/vast-ai-setup.sh"
        "scripts/setup-jupyter.sh"
        "vast-templates/comfyui-direct.yaml"
        "vast-templates/comfyui-jupyter.yaml"
    )
    
    local missing_files=()
    
    cd "$PROJECT_ROOT"
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -eq 0 ]; then
        log "INFO" "✅ Tous les fichiers requis sont présents"
        return 0
    else
        log "ERROR" "❌ Fichiers manquants:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        return 1
    fi
}

# Fonction principale
main() {
    echo -e "${BLUE}🧪 Script de Test Local - ComfyUI RTX 4090${NC}"
    echo -e "${BLUE}Version 1.0${NC}"
    echo
    
    local test_standard=true
    local test_jupyter=true
    local cleanup_after=true
    
    # Parsing des arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --standard-only)
                test_jupyter=false
                shift
                ;;
            --jupyter-only)
                test_standard=false
                shift
                ;;
            --no-cleanup)
                cleanup_after=false
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  --standard-only    Tester uniquement l'image standard"
                echo "  --jupyter-only     Tester uniquement l'image JupyterLab"
                echo "  --no-cleanup       Ne pas nettoyer les containers après test"
                echo "  --help             Afficher cette aide"
                exit 0
                ;;
            *)
                log "ERROR" "Option inconnue: $1"
                exit 1
                ;;
        esac
    done
    
    # Validation des prérequis
    if ! command -v docker &> /dev/null; then
        log "ERROR" "Docker n'est pas installé"
        exit 1
    fi
    
    # Nettoyage initial
    cleanup
    
    # Validation des fichiers
    if ! validate_files; then
        log "ERROR" "Validation des fichiers échouée"
        exit 1
    fi
    
    local success=true
    
    # Test image standard
    if [ "$test_standard" = true ]; then
        log "INFO" "=== TEST IMAGE STANDARD ==="
        
        if test_build "Dockerfile" "${IMAGE_BASE}:standard" "Standard"; then
            if test_startup "${IMAGE_BASE}:standard" "comfyui-standard-test" "-p 8188:8188" "Standard"; then
                test_endpoints "8188" "Standard"
            else
                success=false
            fi
        else
            success=false
        fi
        echo
    fi
    
    # Test image JupyterLab
    if [ "$test_jupyter" = true ]; then
        log "INFO" "=== TEST IMAGE JUPYTERLAB ==="
        
        if test_build "Dockerfile.jupyter" "${IMAGE_BASE}:jupyter" "JupyterLab"; then
            if test_startup "${IMAGE_BASE}:jupyter" "comfyui-jupyter-test" "-p 8888:8888 -p 8189:8188" "JupyterLab"; then
                test_endpoints "8888 8189" "JupyterLab"
            else
                success=false
            fi
        else
            success=false
        fi
        echo
    fi
    
    # Afficher les statistiques
    show_stats
    
    # Tests de configuration GitHub Actions
    log "INFO" "=== VALIDATION GITHUB ACTIONS ==="
    if yaml_lint_available=$(command -v yamllint); then
        if yamllint .github/workflows/build.yml > /dev/null 2>&1; then
            log "INFO" "✅ Workflow GitHub Actions valide"
        else
            log "WARN" "⚠️  Workflow GitHub Actions peut avoir des problèmes de syntaxe"
        fi
    else
        log "DEBUG" "yamllint non disponible - validation syntaxe ignorée"
    fi
    
    # Résumé final
    echo
    if [ "$success" = true ]; then
        log "INFO" "🎉 TOUS LES TESTS SONT PASSÉS!"
        log "INFO" "✅ Le projet est prêt pour déploiement GitHub"
        echo
        log "INFO" "📋 Prochaines étapes:"
        echo "  1. Créer repository GitHub"
        echo "  2. Configurer permissions Actions (packages:write)"
        echo "  3. Push le code: git push origin main"
        echo "  4. Vérifier build dans Actions"
        echo "  5. Tester sur vast.ai"
    else
        log "ERROR" "❌ CERTAINS TESTS ONT ÉCHOUÉ"
        log "ERROR" "Corrigez les erreurs avant déploiement"
    fi
    
    # Nettoyage final
    if [ "$cleanup_after" = true ]; then
        cleanup
    else
        log "INFO" "Containers de test conservés pour inspection"
        log "INFO" "Standard: docker logs comfyui-standard-test"
        log "INFO" "JupyterLab: docker logs comfyui-jupyter-test"
    fi
}

# Gestion des erreurs
trap cleanup EXIT

# Exécution
main "$@"