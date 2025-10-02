# Unsloth Training Environment

This repository contains a Docker-based environment for fine-tuning the LLM using Unsloth, any model can be trained on the environment, SmolLM3 happens to be as an example.

## Prerequisites

- Docker installed on your system
- NVIDIA GPU with CUDA support
- NVIDIA Container Toolkit installed

## 🚀 Quick Start

```bash
docker run -d -e JUPYTER_PASSWORD="mypassword" \
  -p 8888:8888 -p 2222:22 \
  -v $(pwd)/work:/workspace/work \
  --gpus all \
  semhoun/unsloth
```

Access Jupyter Lab at `http://localhost:8888` and start fine-tuning!

## 📋 Features

- **Pre-installed Unsloth environment** - No need to install packages in notebooks, just `import unsloth` and run
- **Ready-to-use notebooks** - The `unsloth-notebooks/` folder contains example fine-tuning notebooks
- **Dual access modes** - Both Jupyter Lab and SSH access available
- **Non-root user setup** - Runs with `unsloth` user for enhanced security
- **GPU-optimized** - Built for NVIDIA GPUs
- **llama.cpp** - Already compiled (just symlink to /opt/llama.cpp)

## 🔧 Configuration Options

##### Environment Variables

| Variable           | Description                               | Default   | Options               |
| :----------------- | :---------------------------------------- | :-------- | :-------------------- |
| `JUPYTER_PORT`     | Jupyter Lab port inside container         | `8888`    | Any valid port        |
| `JUPYTER_PASSWORD` | Jupyter Lab password                      | `unsloth` | Any string            |
| `SSH_KEY`          | SSH public key for authentication         | None      | SSH public key string |
| `USER_PASSWORD`    | Password for `unsloth` user (sudo access) | `unsloth` | Any string            |

## Port Mapping

Map container ports to your host system:

```bash
-p <host_port>:<container_port>
```

**Required mappings:**

- Jupyter Lab: `-p 8000:8888` (or your chosen ports)
- SSH access: `-p 2222:22` (or your chosen ports)

## Volume Mounting

**⚠️ Important:** Containers do not persist data between runs. Use volume mounts to preserve your work.

```bash
-v <local_host_folder>:<container_folder>
```

**Recommended:**

- `-v $(pwd)/work:/workspace/work` - Mount current directory's `work` folder
- `-v ~/notebooks:/workspace/notebooks` - Mount your notebook directory

## 📖 Usage Example

### Full Example

```bash
docker run -d -e JUPYTER_PORT=8000 \
  -e JUPYTER_PASSWORD="mypassword" \
  -e "SSH_KEY=$(cat ~/.ssh/container_key.pub)" \
  -e USER_PASSWORD="unsloth2025" \
  -p 8000:8888 -p 2222:22 \
  -v $(pwd)/work:/workspace/work \
  --gpus all \
  unsloth/unsloth
```

### Setting up SSH Key

If you don't have an SSH key pair:

```bash
# Generate new key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/container_key

# Use the public key in docker run
-e "SSH_KEY=$(cat ~/.ssh/container_key.pub)"

# Connect via SSH
ssh -i ~/.ssh/container_key -p 2222 unsloth@localhost
```

## 🗂️ Container Structure

- `/workspace/work/` - Your mounted work directory
- `/workspace/unsloth-notebooks/` - Example Unsloth fine-tuning notebooks
- `/workspace/notebooks/` - My personnal fine-tuning notebooks
- `/home/unsloth/` - User home directory

## 🔒 Security Notes

- Container runs as non-root `unsloth` user by default
- Use `USER_PASSWORD` for sudo operations inside container
- SSH access requires public key authentication