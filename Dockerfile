# 3.10.11-bullseye,  has python, git, but relatively small (<250MB)
ARG BASE_IMAGE="python@sha256:88fb365ea5d52ec8f5799f40a4742b9fb3c91dac92f7048eabaae194a25ccc28"
ARG GPU_MAKE="nvidia"
ARG UID=1000
ARG GID=1000

FROM ${BASE_IMAGE}
ARG GPU_MAKE
ARG UID
ARG GID

SHELL [ "/bin/bash", "-uec"]
RUN \
  --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
  --mount=target=/var/cache/apt,type=cache,sharing=locked \
<<'EOF'
  apt-get update
  apt-get install -yq \
    git-lfs \
    nano
  echo "machine_learning" >> /etc/hostname
EOF

# run instructions as user
USER ${UID}:${GID}
# run python from future venv
ENV PATH="/app/venv/bin:${PATH}"
# copy context to obvious location
COPY --chown=${UID}:${GID} ./ /app
# create cache directory *with user permissions*
WORKDIR /app/.cache
# default to app directory
WORKDIR /app
# set pip cache location
ENV XDG_CACHE_HOME="/app/.cache/pip"
# run with mounted cache
RUN --mount=type=cache,target=/app/.cache,uid=${UID},gid=${GID} <<'EOF'
  # choose package index based on chosen hardware
  if [ "${GPU_MAKE}" = "nvidia" ]; then
    EXTRA_INDEX_URL="https://download.pytorch.org/whl/cu118"
    EXTRAS="xformers==0.0.17"
  elif [ "${GPU_MAKE}" = "amd" ]; then
    EXTRA_INDEX_URL="https://download.pytorch.org/whl/rocm5.4.2"
    EXTRAS=""
  elif [ "${GPU_MAKE}" = "cpu" ]; then
    EXTRA_INDEX_URL="https://download.pytorch.org/whl/cpu"
    EXTRAS=""
  else
    echo "Unknown GPU_MAKE provided as docker build arg."
    exit 2
  fi
  # create virtual environment to manage packages
  python -m venv venv
  # install framework packages
  pip install \
    --extra-index-url "${EXTRA_INDEX_URL}" \
    install \
    torch \
    torchvision \
    torchaudio \
    ${EXTRAS}
EOF

CMD bash
