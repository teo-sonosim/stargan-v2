# syntax=docker/dockerfile:experimental

FROM continuumio/anaconda3:2020.07

LABEL maintainer="teo@sonosim.com"
ENV LANG C.UTF-8
SHELL ["/bin/bash", "--login", "-c"]

WORKDIR /app
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        make=4.2.1-1.2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
COPY Makefile .
RUN conda init bash && make provision_environment

COPY . /app

ENTRYPOINT ["/bin/bash"]
