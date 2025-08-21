# 🚀 Guide de Déploiement Rapide - ComfyUI RTX 4090

## Étapes de Déploiement

### 1. Créer le Repository GitHub

1. **Créer un nouveau repository** sur GitHub :
   - Nom : `ComfyUI-Docker-RTX4090` (ou nom de votre choix)
   - Visibilité : **Public** (pour GHCR gratuit)
   - ✅ Ajouter README.md
   - ✅ Ajouter .gitignore

2. **Cloner et copier les fichiers** :
   ```bash
   git clone https://github.com/Nic0lasgon/ComfyUI-Docker-RTX4090.git
   cd ComfyUI-Docker-RTX4090
   
   # Copier tous les fichiers du projet local
   cp -r /Users/nicolasgonthier/Travail/ComfyUI-Docker-RTX4090/* .
   ```

### 2. Configurer GitHub Container Registry

1. **Aller dans Settings > Actions > General**
2. **Workflow permissions** → Sélectionner "Read and write permissions"
3. **Actions permissions** → "Allow all actions and reusable workflows"

### 3. Push Initial et Build Automatique

```bash
git add .
git commit -m "🚀 Initial commit - ComfyUI RTX 4090 optimized

- Dockerfile optimisé RTX 4090 avec CUDA 12.8
- JupyterLab avec authentification sécurisée  
- Templates vast.ai pour déploiement rapide
- Scripts automatisés de setup
- Monitoring GPU intégré
- Extensions ComfyUI pré-installées

🎮 Generated with Claude Code
"
git push origin main
```

### 4. Vérifier le Build

1. **Aller dans Actions** sur GitHub
2. **Vérifier que le workflow "Build and Push ComfyUI RTX 4090 to GHCR" démarre**
3. **Attendre la fin du build** (~15-20 minutes)

### 5. URLs des Images Finales

Une fois le build terminé, vos images seront disponibles :

**Image Standard (Accès Direct) :**
```
ghcr.io/Nic0lasgon/comfyui-docker-rtx4090:latest
```

**Image JupyterLab (Sécurisé) :**
```
ghcr.io/Nic0lasgon/comfyui-docker-rtx4090:jupyter
```

## 🎯 Test Rapid sur vast.ai

### Mode 1: Accès Direct (Recommandé pour premier test)

1. **Créer instance vast.ai** :
   - **GPU**: RTX 4090
   - **RAM**: 32GB+
   - **Storage**: 50GB+

2. **Configuration** :
   ```
   Image: ghcr.io/Nic0lasgon/comfyui-docker-rtx4090:latest
   Docker Options: -p 8188:8188 --gpus all
   On-start Script: 
   wget -O /workspace/setup.sh https://raw.githubusercontent.com/Nic0lasgon/ComfyUI-Docker-RTX4090/main/scripts/vast-ai-setup.sh && chmod +x /workspace/setup.sh && /workspace/setup.sh
   ```

3. **Service Web** (pour bouton "Open" direct) :
   - **Name**: ComfyUI
   - **Type**: HTTP
   - **Port**: 8188
   - **Path**: /

### Mode 2: JupyterLab Sécurisé

1. **Configuration** :
   ```
   Image: ghcr.io/Nic0lasgon/comfyui-docker-rtx4090:jupyter
   Docker Options: -p 8888:8888 -p 8188:8188 --gpus all
   Environment Variables:
   JUPYTER_PASSWORD=votre_mot_de_passe_securise
   On-start Script:
   wget -O /workspace/setup.sh https://raw.githubusercontent.com/Nic0lasgon/ComfyUI-Docker-RTX4090/main/scripts/setup-jupyter.sh && chmod +x /workspace/setup.sh && /workspace/setup.sh
   ```

2. **Service Web** :
   - **Name**: JupyterLab  
   - **Type**: HTTP
   - **Port**: 8888
   - **Path**: /

## ⚡ Test de Performance

### Vérifications à faire :

1. **Démarrage** : < 2 minutes pour être opérationnel
2. **Interface accessible** : Clic sur "Open" fonctionne
3. **GPU détecté** : RTX 4090 visible dans ComfyUI
4. **Extensions** : Manager, rgthree, WAS disponibles
5. **Performance** : 
   - FLUX Schnell 1024x1024 : ~3-4s
   - SDXL 1024x1024 : ~1.5-2s

### Monitoring

**SSH dans l'instance :**
```bash
# Logs en temps réel
docker logs -f comfyui-vast

# Stats GPU
nvidia-smi

# Monitoring complet
cd /workspace && ./monitor.sh
```

## 🚨 Troubleshooting

### Build GitHub Actions Échoue

1. **Vérifier permissions** : Settings > Actions > General
2. **Vérifier Dockerfile** : Syntaxe correcte
3. **Logs d'erreur** : Onglet Actions > Build failed

### Instance vast.ai ne démarre pas

1. **Vérifier image** : URL correcte dans configuration
2. **Logs container** : docker logs NOM_CONTAINER
3. **Redémarrer** : docker restart NOM_CONTAINER

### Performance dégradée

1. **Vérifier GPU** : nvidia-smi
2. **Vérifier drivers** : Compatible CUDA 12.8
3. **Vérifier VRAM** : Utilisation < 24GB

## 📞 Support Rapide

**Étapes de débogage :**

1. ✅ **GitHub Actions** : Build réussi ?
2. ✅ **Image disponible** : ghcr.io accessible ?
3. ✅ **vast.ai config** : Ports et GPU corrects ?
4. ✅ **Container running** : docker ps montre container ?
5. ✅ **Logs propres** : Pas d'erreurs fatales ?

---

**🎯 Prochaines étapes :** Une fois le premier test réussi, nous pourrons optimiser et ajouter des modèles personnalisés !