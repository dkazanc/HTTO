FROM continuumio/miniconda3 as conda_upstream

RUN groupadd -r conda --gid 900 \
    && chown -R :conda /opt/conda \
    && chmod -R g+w /opt/conda \
    && find /opt -type d | xargs -n 1 chmod g+s

FROM registry.hub.docker.com/nvidia/cuda:11.7.1-devel-ubuntu20.04
COPY --from=conda_upstream /opt /opt/

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PATH=/opt/conda/bin:$PATH
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

COPY conda/environment_explicit.txt /tmp/conda-env/
RUN umask 0002 \
    && /opt/conda/bin/conda create -n htto --file /tmp/conda-env/environment_explicit.txt --no-default-packages \
    && rm -rf /tmp/conda-env

COPY . ${HTTO_DIR}

RUN /opt/conda/envs/htto/bin/python setup.py install

ENTRYPOINT /opt/conda/envs/htto/bin/python -m htto
