# ⚡ Guide de Démarrage Rapide - ComfyUI RTX 4090

## 🎯 Déployement en 3 Minutes sur vast.ai

### 1. Configurer vast.ai (30 secondes)

**Image Docker :**
```
ghcr.io/VOTRE_USERNAME/comfyui-docker-rtx4090:latest
```

**Docker Options :**
```
-p 8188:8188 --gpus all
```

**On-start Script :**
```bash
wget -O /tmp/setup.sh https://raw.githubusercontent.com/VOTRE_USERNAME/ComfyUI-Docker-RTX4090/main/scripts/vast-ai-setup.sh && chmod +x /tmp/setup.sh && /tmp/setup.sh
```

### 2. Lancer l'Instance (1 minute)

1. Sélectionner **RTX 4090** avec **32GB+ RAM**
2. Coller la configuration ci-dessus
3. Cliquer **Rent**
4. Attendre le démarrage automatique

### 3. Accéder à ComfyUI (30 secondes)

Une fois l'instance démarrée :
```
http://VOTRE_IP_VAST:8188/
```

## 🚀 Test Rapide des Performances

### Workflow de Test FLUX Schnell (4 étapes)

1. **Load Checkpoint** → `flux1-schnell.safetensors`
2. **CLIP Text Encode** → Votre prompt
3. **KSampler** → Steps: 4, CFG: 1.0
4. **VAE Decode** → Connecter à Save Image

**Résultat attendu :** ~3-4 secondes pour 1024x1024

## 📊 Monitoring en Temps Réel

### Accès SSH à l'instance vast.ai
```bash
ssh -p PORT_SSH root@IP_VAST
```

### Lancer le monitoring
```bash
cd /workspace
./scripts/monitor.sh
```

**Indicateurs clés :**
- **GPU Util :** 85-95% (génération active)
- **VRAM :** < 20GB utilisé
- **Temp :** < 80°C optimal

## 🔧 Commandes de Dépannage

### Vérifier le status
```bash
docker ps                          # Container actif ?
docker logs -f comfyui-vast       # Logs en temps réel
nvidia-smi                         # Stats GPU
curl http://localhost:8188/        # Interface accessible ?
```

### Redémarrer proprement
```bash
docker restart comfyui-vast
```

### Logs d'erreurs
```bash
docker logs comfyui-vast | grep -i "error\|exception"
```

## ⚡ Optimisations Actives RTX 4090

- ✅ **CUDA 12.8** - Support Ada Lovelace complet
- ✅ **PyTorch 2.5.1** - Optimisations natives RTX 4090
- ✅ **xFormers** - Accélération mémoire 30%
- ✅ **FP16/FP8** - Tensor Cores optimaux
- ✅ **HIGHVRAM** - Utilisation complète 24GB
- ✅ **Extensions** - 10+ modules pré-installés

## 🎨 Modèles Recommandés

### FLUX (Recommandé RTX 4090)
- **FLUX.1-schnell** - Ultra-rapide (4 steps)
- **FLUX.1-dev** - Qualité maximale

### SDXL (Excellent)
- **Juggernaut XL** - Photoréalisme
- **DreamShaper XL** - Polyvalent

### SD 1.5 (Ultra-rapide)
- **Realistic Vision v6** - Portraits
- **Epic Realism** - Scènes réalistes

## 💰 Gestion des Coûts

### Arrêt automatique
```bash
# Arrêter après inactivité (1h)
echo "docker stop comfyui-vast" | at now + 1 hour
```

### Snapshot avant arrêt
```bash
# Sauvegarder l'état
docker commit comfyui-vast comfyui-snapshot
```

## ❓ FAQ Express

**Q: ComfyUI ne répond pas ?**
```bash
docker restart comfyui-vast && sleep 30 && curl http://localhost:8188/
```

**Q: GPU non détecté ?**
```bash
nvidia-smi  # Si erreur, contacter vast.ai support
```

**Q: Extension manquante ?**
```bash
# Utiliser ComfyUI Manager dans l'interface
# Ou installer manuellement via SSH
```

**Q: Performance faible ?**
```bash
# Vérifier température
nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits
# Si >85°C, ajuster paramètres
```

## 🆘 Support Rapide

**Issues récurrents :**
- Port 8188 fermé → Vérifier config vast.ai
- OOM errors → Réduire batch size
- CUDA errors → Redémarrer instance

**Liens utiles :**
- [Issues GitHub](https://github.com/VOTRE_USERNAME/ComfyUI-Docker-RTX4090/issues)
- [Discord ComfyUI](https://discord.gg/comfyui)
- [Support vast.ai](https://vast.ai/support)

---

**🎯 Objectif atteint ? ComfyUI RTX 4090 opérationnel en moins de 3 minutes !**