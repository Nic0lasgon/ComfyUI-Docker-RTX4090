#!/bin/bash
# Script de monitoring avancé pour ComfyUI RTX 4090
# Version: 1.0

set -euo pipefail

# Configuration
CONTAINER_NAME="comfyui-vast"
LOG_DIR="/workspace/logs"
MONITOR_INTERVAL=30
MAX_TEMP_THRESHOLD=85
MAX_MEMORY_THRESHOLD=95

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Fonction d'affichage avec couleur
print_colored() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Fonction pour créer les logs s'ils n'existent pas
setup_logging() {
    mkdir -p "$LOG_DIR"
    touch "$LOG_DIR/monitor.log"
    touch "$LOG_DIR/gpu_stats.log"
    touch "$LOG_DIR/performance.log"
    touch "$LOG_DIR/alerts.log"
}

# Fonction pour logger avec timestamp
log_with_timestamp() {
    local log_file=$1
    local message=$2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$LOG_DIR/$log_file"
}

# Fonction pour afficher le header du monitoring
show_header() {
    clear
    print_colored "$BLUE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_colored "$BLUE" "🚀 ComfyUI RTX 4090 - Monitoring en Temps Réel"
    print_colored "$BLUE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "Dernière mise à jour: ${GREEN}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo
}

# Fonction pour obtenir les stats GPU
get_gpu_stats() {
    if command -v nvidia-smi &> /dev/null; then
        nvidia-smi --query-gpu=name,utilization.gpu,utilization.memory,memory.used,memory.total,temperature.gpu,power.draw,power.limit --format=csv,noheader,nounits
    else
        echo "N/A,N/A,N/A,N/A,N/A,N/A,N/A,N/A"
    fi
}

# Fonction pour afficher les stats GPU
display_gpu_stats() {
    local gpu_stats=$(get_gpu_stats)
    
    if [ "$gpu_stats" != "N/A,N/A,N/A,N/A,N/A,N/A,N/A,N/A" ]; then
        IFS=',' read -r name gpu_util mem_util mem_used mem_total temp power_draw power_limit <<< "$gpu_stats"
        
        print_colored "$PURPLE" "🎮 INFORMATIONS GPU"
        echo "────────────────────────────────────────────────────────────────────────────────"
        printf "%-20s: %s\n" "Modèle" "$name"
        printf "%-20s: " "Utilisation GPU"
        if (( $(echo "$gpu_util > 80" | bc -l) )); then
            print_colored "$RED" "${gpu_util}%"
        elif (( $(echo "$gpu_util > 50" | bc -l) )); then
            print_colored "$YELLOW" "${gpu_util}%"
        else
            print_colored "$GREEN" "${gpu_util}%"
        fi
        
        printf "%-20s: " "Utilisation Mémoire"
        if (( $(echo "$mem_util > 90" | bc -l) )); then
            print_colored "$RED" "${mem_util}%"
        elif (( $(echo "$mem_util > 70" | bc -l) )); then
            print_colored "$YELLOW" "${mem_util}%"
        else
            print_colored "$GREEN" "${mem_util}%"
        fi
        
        printf "%-20s: %s MB / %s MB\n" "Mémoire VRAM" "$mem_used" "$mem_total"
        
        printf "%-20s: " "Température"
        if (( $(echo "$temp > $MAX_TEMP_THRESHOLD" | bc -l) )); then
            print_colored "$RED" "${temp}°C ⚠️"
            log_with_timestamp "alerts.log" "ALERTE: Température GPU élevée: ${temp}°C"
        elif (( $(echo "$temp > 70" | bc -l) )); then
            print_colored "$YELLOW" "${temp}°C"
        else
            print_colored "$GREEN" "${temp}°C"
        fi
        
        printf "%-20s: %s W / %s W\n" "Consommation" "$power_draw" "$power_limit"
        
        # Logger les stats
        log_with_timestamp "gpu_stats.log" "GPU_UTIL:${gpu_util}%,MEM_UTIL:${mem_util}%,TEMP:${temp}°C,POWER:${power_draw}W"
    else
        print_colored "$RED" "❌ GPU non détecté ou nvidia-smi non disponible"
    fi
}

# Fonction pour obtenir les stats du container
get_container_stats() {
    if docker ps | grep -q "$CONTAINER_NAME"; then
        docker stats "$CONTAINER_NAME" --no-stream --format "table {{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
    else
        echo "Container non trouvé"
    fi
}

# Fonction pour afficher les stats du container
display_container_stats() {
    print_colored "$BLUE" "🐳 STATISTIQUES CONTAINER"
    echo "────────────────────────────────────────────────────────────────────────────────"
    
    if docker ps | grep -q "$CONTAINER_NAME"; then
        local container_status=$(docker inspect -f '{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "unknown")
        local uptime=$(docker inspect -f '{{.State.StartedAt}}' "$CONTAINER_NAME" 2>/dev/null | xargs date -d | xargs -I {} sh -c 'echo $(( ($(date +%s) - $(date -d "{}" +%s)) / 60 )) minutes' 2>/dev/null || echo "unknown")
        
        printf "%-20s: " "Status"
        if [ "$container_status" = "running" ]; then
            print_colored "$GREEN" "✅ $container_status"
        else
            print_colored "$RED" "❌ $container_status"
        fi
        
        printf "%-20s: %s\n" "Uptime" "$uptime"
        
        # Stats en temps réel
        local stats=$(docker stats "$CONTAINER_NAME" --no-stream --format "{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" | tail -n 1)
        if [ -n "$stats" ]; then
            IFS=$'\t' read -r cpu mem net block <<< "$stats"
            printf "%-20s: %s\n" "CPU" "$cpu"
            printf "%-20s: %s\n" "Mémoire" "$mem"
            printf "%-20s: %s\n" "Réseau I/O" "$net"
            printf "%-20s: %s\n" "Disque I/O" "$block"
        fi
        
        # Logger les stats du container
        log_with_timestamp "performance.log" "CONTAINER:$container_status,CPU:$cpu,MEM:$mem"
    else
        print_colored "$RED" "❌ Container '$CONTAINER_NAME' non trouvé"
    fi
}

# Fonction pour vérifier l'état de ComfyUI
check_comfyui_health() {
    print_colored "$GREEN" "🏥 SANTÉ COMFYUI"
    echo "────────────────────────────────────────────────────────────────────────────────"
    
    # Test de connectivité HTTP
    local http_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8188/ 2>/dev/null || echo "000")
    
    printf "%-20s: " "Interface Web"
    if [ "$http_status" = "200" ]; then
        print_colored "$GREEN" "✅ Accessible (HTTP $http_status)"
    else
        print_colored "$RED" "❌ Inaccessible (HTTP $http_status)"
        log_with_timestamp "alerts.log" "ALERTE: Interface web inaccessible (HTTP $http_status)"
    fi
    
    # Test de l'API
    local api_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8188/api/v1/models 2>/dev/null || echo "000")
    printf "%-20s: " "API"
    if [ "$api_status" = "200" ] || [ "$api_status" = "404" ]; then
        print_colored "$GREEN" "✅ Réactive"
    else
        print_colored "$YELLOW" "⚠️  Réponse inattendue"
    fi
    
    # Vérifier les logs récents pour erreurs
    if docker logs "$CONTAINER_NAME" --since 1m 2>/dev/null | grep -i "error\|exception\|traceback" | head -5; then
        print_colored "$RED" "⚠️  Erreurs récentes détectées - voir logs"
    fi
}

# Fonction pour afficher les informations système
display_system_info() {
    print_colored "$YELLOW" "💻 INFORMATIONS SYSTÈME"
    echo "────────────────────────────────────────────────────────────────────────────────"
    
    printf "%-20s: %s\n" "Charge système" "$(uptime | awk -F'load average:' '{print $2}' | xargs)"
    printf "%-20s: %s\n" "Mémoire libre" "$(free -h | awk 'NR==2{printf "%.1fG/%.1fG (%.1f%%)", $7/1024/1024, $2/1024/1024, $7*100/$2}')"
    printf "%-20s: %s\n" "Espace disque" "$(df -h /workspace 2>/dev/null | awk 'NR==2{printf "%s/%s (%s)", $3, $2, $5}' || echo "N/A")"
    printf "%-20s: %s\n" "Heure système" "$(date '+%Y-%m-%d %H:%M:%S %Z')"
}

# Fonction pour afficher les liens rapides
display_quick_links() {
    print_colored "$BLUE" "🔗 LIENS RAPIDES"
    echo "────────────────────────────────────────────────────────────────────────────────"
    echo "ComfyUI Interface: http://localhost:8188/"
    echo "Logs Container:    docker logs -f $CONTAINER_NAME"
    echo "Redémarrer:        docker restart $CONTAINER_NAME"
    echo "Arrêter:           docker stop $CONTAINER_NAME"
    echo
    print_colored "$YELLOW" "📊 FICHIERS DE LOG"
    echo "────────────────────────────────────────────────────────────────────────────────"
    echo "Monitor:     $LOG_DIR/monitor.log"
    echo "GPU Stats:   $LOG_DIR/gpu_stats.log"
    echo "Performance: $LOG_DIR/performance.log"
    echo "Alertes:     $LOG_DIR/alerts.log"
}

# Fonction de monitoring en continu
continuous_monitoring() {
    setup_logging
    
    while true; do
        show_header
        display_gpu_stats
        echo
        display_container_stats
        echo
        check_comfyui_health
        echo
        display_system_info
        echo
        display_quick_links
        
        log_with_timestamp "monitor.log" "Monitoring cycle completed"
        
        echo
        print_colored "$BLUE" "Prochaine mise à jour dans ${MONITOR_INTERVAL}s... (Ctrl+C pour arrêter)"
        sleep "$MONITOR_INTERVAL"
    done
}

# Fonction pour afficher l'aide
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -c, --continuous    Monitoring continu (défaut)"
    echo "  -o, --once         Affichage unique"
    echo "  -i, --interval N   Intervalle en secondes (défaut: 30)"
    echo "  -h, --help         Afficher cette aide"
    echo ""
    echo "Exemples:"
    echo "  $0                 # Monitoring continu avec intervalle par défaut"
    echo "  $0 -o              # Affichage unique"
    echo "  $0 -i 10           # Monitoring avec intervalle de 10s"
}

# Fonction principale
main() {
    local continuous=true
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--continuous)
                continuous=true
                shift
                ;;
            -o|--once)
                continuous=false
                shift
                ;;
            -i|--interval)
                MONITOR_INTERVAL="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "Option inconnue: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    if [ "$continuous" = true ]; then
        continuous_monitoring
    else
        setup_logging
        show_header
        display_gpu_stats
        echo
        display_container_stats
        echo
        check_comfyui_health
        echo
        display_system_info
        echo
        display_quick_links
    fi
}

# Gestion propre de l'interruption
trap 'echo -e "\n${GREEN}Monitoring arrêté.${NC}"; exit 0' INT TERM

# Vérifier les dépendances
if ! command -v bc &> /dev/null; then
    echo "Installation de bc (calculatrice)..."
    apt-get update && apt-get install -y bc 2>/dev/null || echo "Attention: bc non disponible"
fi

# Exécution
main "$@"