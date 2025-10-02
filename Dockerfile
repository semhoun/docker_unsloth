FROM nvidia/cuda:13.0.1-cudnn-devel-ubuntu22.04
LABEL maintainer="nathanael@semhoun.net"

ENV UNSLOTH_DOCKER=true

RUN apt-get update \
  && apt-get install -y \
    pciutils build-essential cmake curl libcurl4-openssl-dev git \
    wget curl ca-certificates sudo htop vim git git-lfs dumb-init tree ssh ripgrep ffmpeg \
    tmux rsync nano acl supervisor \
    python3-pip python-is-python3 python3 \
  && apt-get clean

RUN cd /opt \
  && git clone  --depth 1 https://github.com/ggerganov/llama.cpp \
  && cmake llama.cpp -B llama.cpp/build -DBUILD_SHARED_LIBS=ON -DGGML_NATIVE=OFF -DGGML_CUDA=ON -DGGML_BACKEND_DL=ON -DGGML_CPU_ALL_VARIANTS=ON -DLLAMA_BUILD_TESTS=OFF \
  && cmake --build llama.cpp/build --config Release -j --clean-first --target llama-quantize llama-cli llama-gguf-split llama-mtmd-cli \
  && cp llama.cpp/build/bin/llama-* llama.cpp \
  && rm -rf build

RUN mkdir -p /workspace/.cache/huggingface /workspace/work \
  && groupadd -K GID_MIN=100 -K GID_MAX=499 runtimeusers \
  && groupadd --gid 1000 unsloth \
  && useradd -m -u 1000 -g 1000 -s /bin/bash unsloth \
  && usermod -aG sudo unsloth \
  && gpasswd -a unsloth runtimeusers \
  && chown -R unsloth:runtimeusers /workspace \
  && mkdir -p /var/run/sshd /var/log/ssh /var/log/jupyter /var/log/supervisor \
  && chown unsloth /var/log/jupyter /var/log/supervisor /var/log/ssh /var/run \
  && chmod 400 /var/run/sshd \
  && rm -f /etc/ssh/ssh_host_*
  
RUN  echo "=========================================" > /etc/motd \
  && echo "🦥 Welcome to Unsloth Container!" >> /etc/motd \
  && echo "=========================================" >> /etc/motd \
  && echo "" >> /etc/motd \
  && echo "🚀 Quick Start:" >> /etc/motd \
  && echo "  - Jupyter Lab: http://localhost:8888" >> /etc/motd \
  && echo "  - Working dir: work" >> /etc/motd \
  && echo "  - User: unsloth" >> /etc/motd \
  && echo "" >> /etc/motd \
  && echo "🔧 Directories:" >> /etc/motd \
  && echo "  - Notebooks: unsloth-notebooks" >> /etc/motd \
  && echo "  - HF Cache: .cache/huggingface" >> /etc/motd \
  && echo "  - Persistent disk: work" >> /etc/motd \
  && echo "" >> /etc/motd \
  && echo "💡 Tips:" >> /etc/motd \
  && echo "  - Use tmux for persistent sessions" >> /etc/motd \
  && echo "  - Models and datasets cache automatically" >> /etc/motd \
  && echo "  - Save your work in shared folder/volume bind" >> /etc/motd \
  && echo "  - Check GPU: nvidia-smi" >> /etc/motd \
  && echo "" >> /etc/motd \
  && echo "Happy fine-tuning! 🎯" >> /etc/motd \
  && echo "=========================================" >> /etc/motd
  
RUN git clone https://github.com/unslothai/notebooks.git /tmp/notebooks \
  && mv /tmp/notebooks/nb /workspace/unsloth-notebooks \
  && rm -rf /tmp/notebooks

RUN pip install --no-cache-dir \
    langid \
    jiwer \
    omegaconf \
    einx \
    pyloudnorm \
    openai-whisper \
    uroman \
    MeCab \
    loguru \
    flatten_dict \
    ffmpy \
    randomname \
    argbind \
    tiktoken \
    ftfy \
    importlib-resources \
    ipython \
    librosa \
    markdown2 \
    matplotlib \
    pystoi \
    soundfile \
    tensorboard \
    torch-stoi \
    jupyterlab \
    notebook \
    ipywidgets \
    timm \
    transformers-cfg \
    evaluate \
    huggingface-hub[hf-transfer] \
    hf_xet \
    "math-verify[antlr4_13_2]" \
    wandb \
    "trackio<1.0" \
    tensorboard &&     python3 -m pip install --no-deps \
    descript-audio-codec \
    descript-audiotools \
    julius \
    snac \
  && pip install --no-cache-dir \
    synthetic-data-kit==0.0.3 \
    vllm==0.10.2 \
    unsloth-zoo==2025.9.14 \
    unsloth==2025.9.11 \
  && pip install --force-reinstall transformers==4.56.2 \
  && pip install --no-deps trl==0.23.0 \
  && pip install kernels git+https://github.com/triton-lang/triton.git@05b2c186c1b6c9a08375389d5efe9cb4c401c075#subdirectory=python/triton_kernels \
  && pip install numpy==2.2.6 \
  && pip cache purge \
  && jupyter lab clean
  
COPY root_fs /

RUN cp /opt/llama.cpp/convert_hf_to_gguf.py /opt/llama.cpp/unsloth_convert_hf_to_gguf.py \
  && ln -s /opt/llama.cpp /workspace/llama.cpp \
  && ln -s /opt/llama.cpp /workspace/work/llama.cpp \
  && ln -s /opt/llama.cpp /workspace/unsloth-notebooks/llama.cpp \
  && chown -R unsloth:runtimeusers /workspace /opt/llama.cpp

WORKDIR /workspace

ENV HF_HOME=/workspace/.cache/huggingface \
  HF_HUB_ENABLE_HF_TRANSFER=1 

USER unsloth:runtimeusers

EXPOSE 22
EXPOSE 8888

ENTRYPOINT ["/entrypoint.sh"]
