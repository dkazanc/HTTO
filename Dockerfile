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
    && apt-get install -y \
        cuda-nsight-systems-11-7 \
        cuda-nsight-compute-11-7 \
    && ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

COPY conda/environment.yml /tmp/conda-env/
RUN umask 0002 \
    && /opt/conda/bin/conda env create -n htto --file /tmp/conda-env/environment.yml --no-default-packages \
    && rm -rf /tmp/conda-env

COPY . ${HTTO_DIR}

RUN conda -n htto run setup.py install

ENTRYPOINT nsys profile \
    conda -n htto \
    python -m htto
