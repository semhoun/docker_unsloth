FROM pytorch/pytorch:2.7.1-cuda12.8-cudnn9-devel
LABEL maintainer="nathanael@semhoun.net"

ENV UNSLOTH_DOCKER=true

RUN apt-get update \
  && apt-get install -y screen \
  && apt-get install -y \
    pciutils build-essential cmake curl libcurl4-openssl-dev git \
    wget curl ca-certificates sudo htop vim git git-lfs dumb-init tree ssh ripgrep ffmpeg supervisor \
  && apt-get clean

RUN pip install --upgrade --upgrade-strategy only-if-needed \
    unsloth-zoo \
    unsloth 'vllm<=0.10.1' \
    xformers \
    jupyterlab notebook ipywidgets \
    jupyter-resource-usage jupyterlab-nvdashboard

RUN mkdir -p /workspace \
  && cd /workspace \
  && git clone  --depth 1 https://github.com/ggerganov/llama.cpp \
  && cmake llama.cpp -B llama.cpp/build -DBUILD_SHARED_LIBS=ON -DGGML_NATIVE=OFF -DGGML_CUDA=ON -DGGML_BACKEND_DL=ON -DGGML_CPU_ALL_VARIANTS=ON -DLLAMA_BUILD_TESTS=OFF \
  && cmake --build llama.cpp/build --config Release -j --clean-first --target llama-quantize llama-cli llama-gguf-split llama-mtmd-cli \
  && cp llama.cpp/build/bin/llama-* llama.cpp

COPY root_fs /

RUN git clone https://github.com/unslothai/notebooks.git /tmp/notebooks \
  && mv /tmp/notebooks /workspace/unsloth-notebooks \
  && rm -rf /tmp/notebooks

RUN groupadd -K GID_MIN=100 -K GID_MAX=499 runtimeusers \
  && groupadd --gid 1001 unsloth \
  && useradd -m -u 1001 -g 1001 -s /bin/bash unsloth \
  && usermod -aG sudo unsloth \
  && gpasswd -a unsloth runtimeusers \
  && chown -R unsloth:runtimeusers /workspace \
  && mkdir -p /var/run/sshd /var/log/ssh /var/log/jupyter /var/log/supervisor \
  && chown unsloth /var/log/jupyter /var/log/supervisor \
  && chmod 400 /var/run/sshd

WORKDIR /workspace
USER unsloth:runtimeusers

EXPOSE 22
EXPOSE 8888

ENTRYPOINT ["/entrypoint.sh"]
