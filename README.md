# 🚀 ComfyUI Docker RTX 4090 Optimisé

Une image Docker ComfyUI parfaitement optimisée pour RTX 4090, hébergée gratuitement sur GitHub Container Registry (GHCR) et prête pour déploiement sur vast.ai.

## ✨ Fonctionnalités

- 🎮 **Optimisations RTX 4090** : CUDA 12.8, PyTorch 2.5.1, xFormers
- ⚡ **Performances maximales** : FP16, CUDA malloc, stream optimizations  
- 🔧 **Extensions pré-installées** : 10+ extensions essentielles
- 🔐 **Accès sécurisé** : JupyterLab avec authentification par mot de passe
- 🌐 **Service web vast.ai** : Bouton "Open" direct vers ComfyUI
- 📊 **Monitoring avancé** : GPU, performance, logs rotatifs
- 🚀 **Déploiement automatisé** : Scripts vast.ai clé en main
- 📋 **Logging détaillé** : Suivi des erreurs et performance
- 🎛️ **Modes multiples** : Direct, JupyterLab sécurisé, développement

## 🏗️ Structure du Projet

```
ComfyUI-Docker-RTX4090/
├── Dockerfile                    # Image optimisée RTX 4090 (accès direct)
├── Dockerfile.jupyter            # Image JupyterLab sécurisée
├── docker-compose.yml            # Configuration multi-environnements
├── .dockerignore                 # Exclusions de build
├── .github/workflows/build.yml   # CI/CD automatisé
├── scripts/
│   ├── vast-ai-setup.sh         # Déploiement vast.ai direct
│   ├── setup-jupyter.sh         # Déploiement JupyterLab sécurisé
│   └── monitor.sh               # Monitoring temps réel
├── vast-templates/              # Templates de déploiement
│   ├── comfyui-direct.yaml      # Configuration accès direct
│   └── comfyui-jupyter.yaml     # Configuration JupyterLab
├── config/                      # Configuration utilisateur
└── README.md                    # Cette documentation
```

## 🎯 Optimisations RTX 4090 Incluses

### Technologies
- **CUDA 12.8** - Support Ada Lovelace complet
- **PyTorch 2.5.1+cu124** - Performance native RTX 4090
- **xFormers 0.0.28** - Accélération mémoire jusqu'à 30%
- **Tensor Cores FP16/FP8** - Calculs ultra-rapides

### Paramètres de lancement
```bash
--use-pytorch-cross-attention  # Optimisations attention
--cuda-malloc                  # Gestion mémoire optimisée
--use-stream                   # Parallélisation GPU
--highvram                     # Utilisation complète 24GB
--fast                         # Mode FP8 Ada Lovelace
--force-fp16                   # Précision optimisée
--disable-nan-check            # Performance maximale
```

### Extensions pré-installées
- **ComfyUI Manager** - Gestion des nodes
- **rgthree-comfy** - Workflow amélioré  
- **WAS Node Suite** - Suite complète d'outils
- **ComfyUI Impact Pack** - Enhancement facial
- **IPAdapter Plus** - Transfert de style
- **ComfyUI KJNodes** - Utilitaires pratiques
- **Custom Scripts** - Scripts personnalisés
- **cg-use-everywhere** - Connexions sans fil
- **ComfyUI Essentials** - QOL améliorations
- **Ultimate SD Upscale** - Upscaling avancé

## 🚀 Démarrage Rapide

### 1. Clone le repository

```bash
git clone https://github.com/Nic0lasgon/ComfyUI-Docker-RTX4090.git
cd ComfyUI-Docker-RTX4090
```

### 2A. Construction locale (optionnelle)

```bash
# Construction de l'image
docker build -t comfyui-rtx4090-optimized .

# Ou avec docker-compose
docker-compose build
```

### 2B. Utilisation de l'image GHCR (recommandé)

L'image est automatiquement construite et publiée sur GHCR :

```bash
# Image latest
docker pull ghcr.io/Nic0lasgon/comfyui-docker-rtx4090:latest

# Ou version spécifique
docker pull ghcr.io/Nic0lasgon/comfyui-docker-rtx4090:v1.0.0
```

### 3. Démarrage local

```bash
# Avec docker-compose (recommandé)
docker-compose up -d

# Ou directement avec docker
docker run -d \
  --name comfyui-vast \
  --gpus all \
  -p 8188:8188 \
  -v $(pwd)/models:/home/comfyui/ComfyUI/models \
  -v $(pwd)/output:/home/comfyui/ComfyUI/output \
  ghcr.io/Nic0lasgon/comfyui-docker-rtx4090:latest
```

## 🌐 Déploiement sur vast.ai

### 🎯 Choix du Mode de Déploiement

#### Mode 1: Accès Direct (Recommandé pour usage simple)
- ✅ **Bouton "Open" direct** vers ComfyUI
- ✅ **Performance maximale** 
- ❌ **Pas d'authentification**
- ❌ **Accès public sur Internet**

#### Mode 2: JupyterLab Sécurisé (Recommandé pour production)
- ✅ **Authentification par mot de passe**
- ✅ **Interface Jupyter** + ComfyUI intégré
- ✅ **Notebooks pour documentation**
- ✅ **Accès sécurisé**
- ⚠️ **Complexité légèrement supérieure**

### Configuration Accès Direct

**Image Docker :**
```
ghcr.io/Nic0lasgon/comfyui-docker-rtx4090:latest
```

**Docker Options :**
```bash
-p 8188:8188 --gpus all
```

**On-start Script :**
```bash
#!/bin/bash
wget -O /workspace/vast-ai-setup.sh https://raw.githubusercontent.com/Nic0lasgon/ComfyUI-Docker-RTX4090/main/scripts/vast-ai-setup.sh
chmod +x /workspace/vast-ai-setup.sh
/workspace/vast-ai-setup.sh
```

### Configuration JupyterLab Sécurisé

**Image Docker :**
```
ghcr.io/Nic0lasgon/comfyui-docker-rtx4090:jupyter
```

**Docker Options :**
```bash
-p 8888:8888 -p 8188:8188 --gpus all
```

**Variables d'environnement :**
```bash
JUPYTER_PASSWORD=votre_mot_de_passe_ici
```

**On-start Script :**
```bash
#!/bin/bash
wget -O /workspace/setup-jupyter.sh https://raw.githubusercontent.com/Nic0lasgon/ComfyUI-Docker-RTX4090/main/scripts/setup-jupyter.sh
chmod +x /workspace/setup-jupyter.sh
/workspace/setup-jupyter.sh
```

### Template vast.ai optimisé

```bash
# GPU recommandé
RTX 4090 (24GB VRAM)

# RAM minimum
32GB

# Stockage recommandé  
50GB+ (pour modèles)

# Région
Choisir selon latence/coût
```

## 📊 Monitoring et Logs

### Script de monitoring temps réel

```bash
# Monitoring continu
./scripts/monitor.sh

# Affichage unique
./scripts/monitor.sh --once

# Monitoring avec intervalle personnalisé
./scripts/monitor.sh --interval 10
```

### Logs disponibles

- **monitor.log** - Cycles de monitoring
- **gpu_stats.log** - Statistiques GPU détaillées  
- **performance.log** - Performance container
- **alerts.log** - Alertes système

### Commandes utiles

```bash
# Logs ComfyUI en temps réel
docker logs -f comfyui-vast

# Stats container
docker stats comfyui-vast

# Stats GPU
nvidia-smi

# Redémarrer ComfyUI
docker restart comfyui-vast

# Accès shell container
docker exec -it comfyui-vast bash
```

## 🔧 Configuration Avancée

### Variables d'environnement

```bash
# Optimisations mémoire RTX 4090
PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
CUDA_VISIBLE_DEVICES=0
TORCH_CUDA_ARCH_LIST=8.9

# Performance
FORCE_CUDA=1
MAX_JOBS=8
```

### Volumes persistants

```yaml
volumes:
  - comfyui_models:/home/comfyui/ComfyUI/models
  - comfyui_output:/home/comfyui/ComfyUI/output
  - comfyui_input:/home/comfyui/ComfyUI/input
  - comfyui_logs:/home/comfyui/ComfyUI/logs
  - comfyui_cache:/home/comfyui/.cache
```

### Configuration réseau

```bash
# Port par défaut
8188:8188

# Accès externe vast.ai
http://VOTRE_IP_PUBLIQUE:8188/
```

## ⚡ Performance Attendues (RTX 4090)

| Modèle | Résolution | Steps | Temps Approx |
|--------|------------|-------|--------------|
| FLUX Schnell | 1024x1024 | 4 | ~3-4s |
| SDXL | 1024x1024 | 20 | ~1.5-2s |
| SD 1.5 | 512x512 | 20 | ~0.8s |

## 🚨 Dépannage

### Problèmes courants

**Image lente**
```bash
# Vérifier utilisation GPU
nvidia-smi

# Vérifier logs erreurs
docker logs comfyui-vast | grep -i error

# Redémarrer proprement
docker restart comfyui-vast
```

**Erreurs CUDA**
```bash
# Vérifier drivers NVIDIA
nvidia-smi

# Vérifier version CUDA container
docker exec comfyui-vast python -c "import torch; print(torch.version.cuda)"

# Reconstruire si nécessaire
docker-compose build --no-cache
```

**Extensions manquantes**
```bash
# Accéder au container
docker exec -it comfyui-vast bash

# Installer extension manuelle
cd /home/comfyui/ComfyUI/custom_nodes
git clone https://github.com/EXTENSION_REPO.git
pip3 install --user -r EXTENSION_DIR/requirements.txt

# Redémarrer ComfyUI
docker restart comfyui-vast
```

**Interface inaccessible**
```bash
# Vérifier port binding
docker port comfyui-vast

# Vérifier firewall vast.ai
# Assurer que port 8188 est ouvert

# Tester localement
curl http://localhost:8188/
```

## 💰 Optimisation des Coûts vast.ai

### Conseils économiques
- ✅ Arrêter l'instance quand inutilisée
- ✅ Utiliser volumes persistants pour modèles
- ✅ Choisir régions moins chères
- ✅ Monitorer bandwidth usage
- ✅ Utiliser snapshot pour configurations

### Commandes d'arrêt propre
```bash
# Sauvegarder état
docker commit comfyui-vast comfyui-snapshot

# Arrêter proprement
docker stop comfyui-vast

# Redémarrer depuis snapshot
docker run -d --name comfyui-vast --gpus all -p 8188:8188 comfyui-snapshot
```

## 🔒 Sécurité

### Bonnes pratiques
- 🔒 Ne pas exposer ports sensibles
- 🔒 Utiliser images vérifiées uniquement  
- 🔒 Surveiller accès non autorisés
- 🔒 Backup configurations importantes
- 🔒 Mise à jour régulière des dépendances

### Configuration firewall
```bash
# Ouvrir uniquement port nécessaire
ufw allow 8188

# Bloquer accès admin si non nécessaire
ufw deny 22
```

## 📈 CI/CD et Mise à Jour

### GitHub Actions

Le workflow automatisé :
- ✅ Build sur push/PR
- ✅ Tests automatiques
- ✅ Publication GHCR
- ✅ Scan sécurité
- ✅ Multi-architecture (à venir)

### Mise à jour de l'image

```bash
# Pull dernière version
docker pull ghcr.io/Nic0lasgon/comfyui-docker-rtx4090:latest

# Recréer container
docker-compose down
docker-compose pull
docker-compose up -d
```

## 🤝 Contribution

### Développement local

```bash
# Clone + développement
git clone https://github.com/Nic0lasgon/ComfyUI-Docker-RTX4090.git
cd ComfyUI-Docker-RTX4090

# Mode développement
docker-compose --profile dev up -d

# Build + test
docker-compose build
docker-compose run --rm comfyui-rtx4090 ./check_setup.sh
```

### Proposer des améliorations

1. Fork le repository
2. Créer une branche feature
3. Implémenter les changements
4. Tester localement
5. Soumettre PR avec description détaillée

## 📝 Licence

MIT License - Voir [LICENSE](LICENSE) pour détails.

## 🙏 Remerciements

- [ComfyUI](https://github.com/comfyanonymous/ComfyUI) - Interface utilisateur exceptionnelle
- [vast.ai](https://vast.ai) - Infrastructure GPU accessible
- [NVIDIA](https://nvidia.com) - Optimisations RTX 4090
- Communauté ComfyUI pour les extensions

## 📞 Support

### Resources utiles
- 📚 [Documentation ComfyUI](https://github.com/comfyanonymous/ComfyUI)
- 💬 [Discord ComfyUI](https://discord.gg/comfyui)
- 🐛 [Issues GitHub](https://github.com/Nic0lasgon/ComfyUI-Docker-RTX4090/issues)
- 🚀 [vast.ai Docs](https://vast.ai/docs/)

### Contact
- 📧 Email : support@VOTRE_DOMAIN.com
- 🐦 Twitter : @VOTRE_TWITTER
- 💼 LinkedIn : /in/VOTRE_LINKEDIN

---

<div align="center">

**🚀 ComfyUI RTX 4090 Optimisé - Performance Maximale sur vast.ai**

[![Build Status](https://github.com/Nic0lasgon/ComfyUI-Docker-RTX4090/workflows/build/badge.svg)](https://github.com/Nic0lasgon/ComfyUI-Docker-RTX4090/actions)
[![Docker Image](https://ghcr-badge.egpl.dev/Nic0lasgon/comfyui-docker-rtx4090/latest_tag?trim=major&label=latest)](https://github.com/Nic0lasgon/ComfyUI-Docker-RTX4090/pkgs/container/comfyui-docker-rtx4090)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

</div>