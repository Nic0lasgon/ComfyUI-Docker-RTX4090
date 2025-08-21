# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Docker-based ComfyUI setup optimized specifically for RTX 4090 GPUs, designed for deployment on vast.ai cloud GPU instances. The project provides two deployment modes: direct access and secure JupyterLab access.

## Architecture

- **Dockerfile**: Main optimized image for RTX 4090 with CUDA 12.8, PyTorch 2.5.1, and xFormers
- **Dockerfile.jupyter**: Secure JupyterLab variant with password authentication
- **docker-compose.yml**: Multi-service configuration supporting dev, production, and jupyter profiles
- **scripts/**: Deployment and monitoring scripts for vast.ai
- **vast-templates/**: YAML templates for vast.ai deployment configurations

## Essential Commands

### Building and Development
```bash
# Build locally
make build

# Build without cache
make build-no-cache

# Build JupyterLab variant
make build-jupyter

# Development mode (port 8189)
make dev
```

### Running Services
```bash
# Start with docker-compose
make run

# Start development profile
docker-compose --profile dev up -d

# Start JupyterLab secure mode
docker-compose --profile jupyter up -d

# Start locally with direct docker
make run-local
```

### Monitoring and Debugging
```bash
# View logs
make logs

# Real-time monitoring (GPU stats)
make monitor

# Check container status and connectivity
make status

# Access container shell
make shell

# GPU information
make gpu-info
```

### Deployment
```bash
# Pull latest from GHCR
make pull

# Update to latest version
make update

# Generate vast.ai configuration
make setup-vast

# Test image functionality
make test
```

### Maintenance
```bash
# Stop services
make stop

# Restart services
make restart

# Clean unused containers/images
make clean

# Complete cleanup (removes volumes)
make clean-all
```

## Key Configuration

### RTX 4090 Optimizations
- CUDA 12.8 for Ada Lovelace architecture
- PyTorch 2.5.1+cu124 with native RTX 4090 support
- xFormers 0.0.28 for 30% memory acceleration
- Optimized launch parameters: `--use-pytorch-cross-attention --cuda-malloc --highvram --fast --force-fp16`

### Environment Variables
- `PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512`
- `TORCH_CUDA_ARCH_LIST=8.9` (Ada Lovelace)
- `FORCE_CUDA=1`

### Pre-installed Extensions
- ComfyUI Manager, rgthree-comfy, WAS Node Suite
- ComfyUI Impact Pack, IPAdapter Plus, KJNodes
- Ultimate SD Upscale, ComfyUI Essentials
- Custom Scripts, cg-use-everywhere

## Deployment Modes

### Direct Access Mode
- Image: `ghcr.io/Nic0lasgon/comfyui-docker-rtx4090:latest`
- Port: 8188
- Use script: `scripts/vast-ai-setup.sh`

### JupyterLab Secure Mode  
- Image: `ghcr.io/Nic0lasgon/comfyui-docker-rtx4090:jupyter`
- Ports: 8888 (JupyterLab), 8188 (ComfyUI)
- Default password: `comfyui4090`
- Use script: `scripts/setup-jupyter.sh`

## Performance Expectations

Expected performance on RTX 4090:
- FLUX Schnell 1024x1024 (4 steps): ~3-4s
- SDXL 1024x1024 (20 steps): ~1.5-2s
- SD 1.5 512x512 (20 steps): ~0.8s

## Troubleshooting

### Common Issues
- **CUDA errors**: Check `nvidia-smi`, verify CUDA version with `docker exec comfyui-vast python -c "import torch; print(torch.version.cuda)"`
- **Slow performance**: Verify GPU utilization with `nvidia-smi`, check logs for errors
- **Missing extensions**: Access container and manually install in `/home/comfyui/ComfyUI/custom_nodes`
- **Connection issues**: Verify port binding with `docker port comfyui-vast`, test with `curl http://localhost:8188/`

### Key Files to Check
- Container logs: `docker logs -f comfyui-vast`
- GPU monitoring: `/home/comfyui/ComfyUI/logs/gpu_monitor.log`
- ComfyUI logs: `/home/comfyui/ComfyUI/logs/comfyui.log`
- Performance logs: `/home/comfyui/ComfyUI/logs/performance.log`

## Volume Management

Persistent volumes:
- `comfyui_models`: AI models storage
- `comfyui_output`: Generated images
- `comfyui_input`: Input images
- `comfyui_logs`: Application logs
- `comfyui_cache`: Performance cache
- `comfyui_notebooks`: JupyterLab notebooks (jupyter profile only)