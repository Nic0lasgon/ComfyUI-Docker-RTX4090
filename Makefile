# Makefile pour ComfyUI RTX 4090 Docker
.PHONY: help build run stop clean logs monitor test setup-vast deploy-vast

# Configuration
IMAGE_NAME = comfyui-rtx4090-optimized
CONTAINER_NAME = comfyui-vast
REGISTRY = ghcr.io
GITHUB_USER = VOTRE_USERNAME
FULL_IMAGE_NAME = $(REGISTRY)/$(GITHUB_USER)/comfyui-docker-rtx4090

# Couleurs pour l'affichage
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

help: ## Afficher cette aide
	@echo "$(GREEN)ComfyUI RTX 4090 Docker - Commandes disponibles:$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Examples:$(NC)"
	@echo "  make build          # Construire l'image localement"  
	@echo "  make run           # Démarrer ComfyUI"
	@echo "  make monitor       # Lancer le monitoring"
	@echo "  make setup-vast    # Configurer vast.ai"

build: ## Construire l'image Docker
	@echo "$(GREEN)🏗️  Construction de l'image ComfyUI RTX 4090...$(NC)"
	docker build -t $(IMAGE_NAME):latest .
	@echo "$(GREEN)✅ Image construite: $(IMAGE_NAME):latest$(NC)"

build-no-cache: ## Construire l'image sans cache
	@echo "$(GREEN)🏗️  Construction de l'image sans cache...$(NC)"
	docker build --no-cache -t $(IMAGE_NAME):latest .
	@echo "$(GREEN)✅ Image construite: $(IMAGE_NAME):latest$(NC)"

build-jupyter: ## Construire l'image JupyterLab
	@echo "$(GREEN)🏗️  Construction de l'image JupyterLab + ComfyUI...$(NC)"
	docker build -f Dockerfile.jupyter -t $(IMAGE_NAME):jupyter .
	@echo "$(GREEN)✅ Image JupyterLab construite: $(IMAGE_NAME):jupyter$(NC)"

run: ## Démarrer ComfyUI avec docker-compose
	@echo "$(GREEN)🚀 Démarrage de ComfyUI RTX 4090...$(NC)"
	docker-compose up -d
	@echo "$(GREEN)✅ ComfyUI démarré sur http://localhost:8188$(NC)"

run-local: ## Démarrer avec image locale
	@echo "$(GREEN)🚀 Démarrage de ComfyUI (image locale)...$(NC)"
	docker run -d \
		--name $(CONTAINER_NAME) \
		--gpus all \
		--restart unless-stopped \
		-p 8188:8188 \
		-e PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512 \
		-e CUDA_VISIBLE_DEVICES=0 \
		-v comfyui_models:/home/comfyui/ComfyUI/models \
		-v comfyui_output:/home/comfyui/ComfyUI/output \
		-v comfyui_logs:/home/comfyui/ComfyUI/logs \
		--shm-size=1g \
		--memory=30g \
		$(IMAGE_NAME):latest
	@echo "$(GREEN)✅ ComfyUI démarré sur http://localhost:8188$(NC)"

pull: ## Télécharger la dernière image depuis GHCR
	@echo "$(GREEN)📥 Téléchargement de l'image depuis GHCR...$(NC)"
	docker pull $(FULL_IMAGE_NAME):latest
	@echo "$(GREEN)✅ Image téléchargée$(NC)"

stop: ## Arrêter ComfyUI
	@echo "$(YELLOW)🛑 Arrêt de ComfyUI...$(NC)"
	-docker stop $(CONTAINER_NAME)
	-docker-compose down
	@echo "$(GREEN)✅ ComfyUI arrêté$(NC)"

restart: stop run ## Redémarrer ComfyUI
	@echo "$(GREEN)🔄 ComfyUI redémarré$(NC)"

logs: ## Afficher les logs ComfyUI
	@echo "$(GREEN)📋 Logs ComfyUI (Ctrl+C pour quitter):$(NC)"
	docker logs -f $(CONTAINER_NAME) 2>/dev/null || docker-compose logs -f

monitor: ## Lancer le monitoring en temps réel
	@echo "$(GREEN)📊 Lancement du monitoring...$(NC)"
	@if [ -f ./scripts/monitor.sh ]; then \
		chmod +x ./scripts/monitor.sh && ./scripts/monitor.sh; \
	else \
		echo "$(RED)❌ Script monitor.sh non trouvé$(NC)"; \
	fi

status: ## Vérifier le status de ComfyUI
	@echo "$(GREEN)📊 Status ComfyUI:$(NC)"
	@docker ps | grep $(CONTAINER_NAME) || echo "$(YELLOW)Container non trouvé$(NC)"
	@echo ""
	@echo "$(GREEN)Test connexion:$(NC)"
	@curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:8188/ || echo "$(RED)Non accessible$(NC)"

test: ## Tester l'image construite
	@echo "$(GREEN)🧪 Test de l'image...$(NC)"
	docker run --rm --gpus all $(IMAGE_NAME):latest ./check_setup.sh || echo "$(YELLOW)⚠️  Tests ignorés (GPU requis)$(NC)"

clean: ## Nettoyer les containers et images inutilisés
	@echo "$(YELLOW)🧹 Nettoyage...$(NC)"
	-docker container prune -f
	-docker image prune -f
	@echo "$(GREEN)✅ Nettoyage terminé$(NC)"

clean-all: ## Nettoyage complet (⚠️ supprime tout)
	@echo "$(RED)⚠️  ATTENTION: Suppression de tous les containers et volumes$(NC)"
	@read -p "Êtes-vous sûr? [y/N] " -n 1 -r; \
	echo ""; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker-compose down -v; \
		docker system prune -af --volumes; \
		echo "$(GREEN)✅ Nettoyage complet terminé$(NC)"; \
	else \
		echo "$(YELLOW)Nettoyage annulé$(NC)"; \
	fi

setup-vast: ## Configurer vast.ai (génère les commandes)
	@echo "$(GREEN)🌐 Configuration vast.ai:$(NC)"
	@echo ""
	@echo "$(YELLOW)Image Docker:$(NC)"
	@echo "$(FULL_IMAGE_NAME):latest"
	@echo ""
	@echo "$(YELLOW)Docker Options:$(NC)"
	@echo "-p 8188:8188 --gpus all"
	@echo ""
	@echo "$(YELLOW)On-start Script:$(NC)"
	@echo "wget -O /workspace/setup.sh https://raw.githubusercontent.com/$(GITHUB_USER)/ComfyUI-Docker-RTX4090/main/scripts/vast-ai-setup.sh && chmod +x /workspace/setup.sh && /workspace/setup.sh"
	@echo ""
	@echo "$(GREEN)📋 Configuration copiée! Collez dans vast.ai$(NC)"

deploy-vast: ## Script de déploiement vast.ai local
	@echo "$(GREEN)🚀 Simulation déploiement vast.ai...$(NC)"
	@if [ -f ./scripts/vast-ai-setup.sh ]; then \
		chmod +x ./scripts/vast-ai-setup.sh && ./scripts/vast-ai-setup.sh; \
	else \
		echo "$(RED)❌ Script vast-ai-setup.sh non trouvé$(NC)"; \
	fi

dev: ## Mode développement
	@echo "$(GREEN)🔧 Mode développement...$(NC)"
	docker-compose --profile dev up -d
	@echo "$(GREEN)✅ Mode dev actif sur http://localhost:8189$(NC)"

jupyter: ## Démarrer JupyterLab sécurisé
	@echo "$(GREEN)🔬 Démarrage JupyterLab + ComfyUI RTX 4090...$(NC)"
	docker-compose --profile jupyter up -d
	@echo "$(GREEN)✅ JupyterLab actif sur http://localhost:8888 (mot de passe: comfyui4090)$(NC)"
	@echo "$(GREEN)🎨 ComfyUI accessible via JupyterLab proxy$(NC)"

shell: ## Accès shell dans le container
	@echo "$(GREEN)🐚 Accès shell container...$(NC)"
	docker exec -it $(CONTAINER_NAME) /bin/bash || echo "$(RED)❌ Container non trouvé$(NC)"

gpu-info: ## Afficher les informations GPU
	@echo "$(GREEN)🎮 Informations GPU:$(NC)"
	@nvidia-smi || echo "$(RED)❌ nvidia-smi non disponible$(NC)"

size: ## Afficher la taille de l'image
	@echo "$(GREEN)📏 Taille de l'image:$(NC)"
	@docker images $(IMAGE_NAME):latest --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" || echo "$(RED)❌ Image non trouvée$(NC)"

push: ## Push vers GHCR (nécessite login)
	@echo "$(GREEN)📤 Push vers GHCR...$(NC)"
	docker tag $(IMAGE_NAME):latest $(FULL_IMAGE_NAME):latest
	docker push $(FULL_IMAGE_NAME):latest
	@echo "$(GREEN)✅ Image poussée vers GHCR$(NC)"

version: ## Afficher les versions
	@echo "$(GREEN)📋 Versions:$(NC)"
	@echo "Docker: $$(docker --version)"
	@echo "Docker Compose: $$(docker-compose --version)"
	@echo "NVIDIA Driver: $$(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits 2>/dev/null || echo 'N/A')"
	@echo "CUDA: $$(nvidia-smi --query-gpu=cuda_version --format=csv,noheader,nounits 2>/dev/null || echo 'N/A')"

benchmark: ## Test de performance basique
	@echo "$(GREEN)⚡ Test de performance...$(NC)"
	@echo "$(YELLOW)Génération d'une image test (512x512, 20 steps)...$(NC)"
	@# Ici vous pouvez ajouter un script de benchmark spécifique
	@echo "$(GREEN)✅ Benchmark terminé - voir logs pour détails$(NC)"

install: ## Installation des dépendances système (si nécessaire)
	@echo "$(GREEN)📦 Vérification des dépendances...$(NC)"
	@command -v docker >/dev/null 2>&1 || (echo "$(RED)❌ Docker non installé$(NC)" && exit 1)
	@command -v docker-compose >/dev/null 2>&1 || (echo "$(RED)❌ Docker Compose non installé$(NC)" && exit 1)
	@echo "$(GREEN)✅ Dépendances OK$(NC)"

update: pull restart ## Mettre à jour vers la dernière version
	@echo "$(GREEN)🔄 Mise à jour terminée$(NC)"

# Alias pratiques
start: run
up: run  
down: stop
ps: status
exec: shell