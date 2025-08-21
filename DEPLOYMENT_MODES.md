# 🚀 Guide des Modes de Déploiement - ComfyUI RTX 4090

## Vue d'Ensemble

Ce projet propose **2 modes principaux** de déploiement sur vast.ai, chacun optimisé pour des cas d'usage spécifiques.

## 🎯 Comparaison des Modes

| Critère | 🎮 Accès Direct | 🔐 JupyterLab Sécurisé |
|---------|----------------|----------------------|
| **🚀 Simplicité** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **🔒 Sécurité** | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **⚡ Performance** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **📚 Fonctionnalités** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **👥 Usage équipe** | ⭐⭐ | ⭐⭐⭐⭐⭐ |

---

## 🎮 Mode 1: Accès Direct

### 🎯 Cas d'Usage Idéaux
- **Tests rapides** et prototypage
- **Usage personnel** sans partage
- **Environnement de développement** privé
- **Performance maximale** requise

### ✅ Avantages
- **Démarrage ultra-rapide** : ComfyUI accessible en 30 secondes
- **Bouton "Open" direct** dans vast.ai → ComfyUI instantané
- **Performance native** : Aucune couche d'abstraction
- **Configuration minimale** : Un seul script de setup
- **Ressources optimisées** : Mémoire entièrement dédiée à ComfyUI

### ❌ Inconvénients
- **Aucune authentification** : Interface accessible publiquement
- **Pas de notebooks** : Interface ComfyUI uniquement
- **Sécurité limitée** : Exposition directe port 8188
- **Pas de gestion utilisateurs** : Accès unique

### 🔧 Configuration Technique

**Image :** `ghcr.io/Nic0lasgon/comfyui-docker-rtx4090:latest`

**Dockerfile :** `Dockerfile` (standard)

**Ports exposés :**
- `8188` → ComfyUI Interface

**Script de setup :** `scripts/vast-ai-setup.sh`

**Template vast.ai :** `vast-templates/comfyui-direct.yaml`

### 📊 Performance Attendue
- **Démarrage :** ~30-60 secondes
- **FLUX Schnell :** ~3-4s (1024x1024)
- **SDXL :** ~1.5-2s (1024x1024)
- **Utilisation VRAM :** 20-22GB (optimal RTX 4090)

---

## 🔐 Mode 2: JupyterLab Sécurisé

### 🎯 Cas d'Usage Idéaux
- **Production** avec accès Internet
- **Collaboration équipe** avec partage sécurisé
- **Environnements professionnels** nécessitant authentification
- **Documentation** et workflows reproductibles
- **Développement avancé** avec notebooks

### ✅ Avantages
- **Authentification robuste** : Mot de passe personnalisable
- **Interface Jupyter complète** : Notebooks, terminal, file manager
- **ComfyUI intégré** : Accessible via proxy dans JupyterLab
- **Documentation interactive** : Notebooks pré-configurés
- **Monitoring avancé** : Outils de développement intégrés
- **Multi-utilisateurs** : Gestion des sessions
- **Backup facile** : Notebooks et configurations versionnés

### ❌ Inconvénients
- **Complexité supérieure** : Configuration plus avancée
- **Démarrage plus lent** : ~90-120 secondes
- **Overhead mémoire** : ~1-2GB pour JupyterLab
- **Courbe d'apprentissage** : Interface Jupyter à maîtriser

### 🔧 Configuration Technique

**Image :** `ghcr.io/Nic0lasgon/comfyui-docker-rtx4090:jupyter`

**Dockerfile :** `Dockerfile.jupyter` (avec JupyterLab)

**Ports exposés :**
- `8888` → JupyterLab Interface (sécurisée)
- `8188` → ComfyUI (accès via proxy)

**Script de setup :** `scripts/setup-jupyter.sh`

**Template vast.ai :** `vast-templates/comfyui-jupyter.yaml`

### 🔑 Configuration Authentification

**Mot de passe par défaut :** `comfyui4090`

**Personnalisation :**
```bash
# Variables d'environnement vast.ai
JUPYTER_PASSWORD=votre_mot_de_passe_securise
```

**Génération hash personnalisé :**
```bash
python3 -c "from jupyter_server.auth import passwd; print(passwd('votre_password'))"
```

### 📊 Performance Attendue
- **Démarrage :** ~90-120 secondes
- **FLUX Schnell :** ~3.5-4.5s (overhead minimal)
- **SDXL :** ~1.8-2.3s (overhead minimal)
- **Utilisation VRAM :** 20-22GB (ComfyUI) + 1-2GB (système)

---

## 🚀 Guide de Choix Rapide

### Choisissez **Accès Direct** si :
- ✅ Vous travaillez **seul**
- ✅ Vous voulez la **performance maximale**
- ✅ Vous faites des **tests rapides**
- ✅ La **sécurité** n'est pas critique
- ✅ Vous voulez la **simplicité absolue**

### Choisissez **JupyterLab Sécurisé** si :
- ✅ Vous partagez l'accès avec d'**autres personnes**
- ✅ Vous travaillez sur Internet **public**
- ✅ Vous voulez **documenter** vos workflows
- ✅ Vous avez besoin d'**authentification**
- ✅ Vous développez des **solutions professionnelles**

---

## 📋 Templates de Déploiement

### Template Accès Direct
```yaml
# Copier le contenu de vast-templates/comfyui-direct.yaml
image: ghcr.io/Nic0lasgon/comfyui-docker-rtx4090:latest
services:
  - name: ComfyUI
    type: http
    port: 8188
    path: /
```

### Template JupyterLab Sécurisé
```yaml
# Copier le contenu de vast-templates/comfyui-jupyter.yaml
image: ghcr.io/Nic0lasgon/comfyui-docker-rtx4090:jupyter
services:
  - name: JupyterLab
    type: http
    port: 8888
    path: /
environment:
  JUPYTER_PASSWORD: "votre_mot_de_passe"
```

---

## 🔄 Migration entre Modes

### De Direct vers JupyterLab
```bash
# 1. Sauvegarder les modèles et outputs
docker cp comfyui-vast:/home/comfyui/ComfyUI/models /backup/
docker cp comfyui-vast:/home/comfyui/ComfyUI/output /backup/

# 2. Arrêter et recréer avec JupyterLab
docker stop comfyui-vast
make jupyter

# 3. Restaurer les données
docker cp /backup/models comfyui-jupyter:/home/jupyter/ComfyUI/
docker cp /backup/output comfyui-jupyter:/home/jupyter/ComfyUI/
```

### De JupyterLab vers Direct
```bash
# 1. Sauvegarder (même processus)
# 2. Recréer en mode direct
docker stop comfyui-jupyter
make run
# 3. Restaurer
```

---

## 💡 Conseils Pro

### Optimisations Accès Direct
- Utilisez `--fast` pour FP8 sur RTX 4090
- Configurez `--highvram` pour utiliser les 24GB
- Surveillez nvidia-smi pendant génération

### Optimisations JupyterLab  
- Changez le mot de passe par défaut **immédiatement**
- Utilisez notebooks pour documenter vos prompts
- Exploitez les extensions Jupyter pour monitoring

### Sécurité Recommandée
- **Mode Direct :** Utilisez uniquement en environnement privé
- **Mode JupyterLab :** Mot de passe fort (12+ caractères)
- **Tous modes :** Surveillez les logs d'accès

---

## 🆘 Dépannage par Mode

### Problèmes Accès Direct
```bash
# Interface non accessible
curl http://localhost:8188/  # Test local
docker logs comfyui-vast     # Vérifier erreurs

# Performance dégradée  
nvidia-smi                   # Vérifier GPU
docker stats comfyui-vast   # Vérifier ressources
```

### Problèmes JupyterLab
```bash
# Authentification échoue
docker logs comfyui-jupyter | grep password
# Régénérer hash mot de passe si nécessaire

# ComfyUI inaccessible via proxy
curl http://localhost:8188/  # Test ComfyUI direct
curl http://localhost:8888/proxy/8188/  # Test proxy
```

---

**🎯 Conclusion :** Les deux modes offrent des optimisations RTX 4090 identiques. Le choix dépend de vos besoins en sécurité et fonctionnalités avancées.