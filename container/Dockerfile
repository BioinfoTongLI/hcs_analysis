FROM  nvidia/cuda:11.0.3-cudnn8-runtime-ubuntu20.04

# Install update apt and install wget package
RUN apt-get update && \
    apt-get install -y wget

# Create user analysis
RUN useradd -m hcs_analysis

# switch user to analysis
USER hcs_analysis

# Install miniconda
RUN cd /home/hcs_analysis && \
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    bash Miniconda3-latest-Linux-x86_64.sh -b -p /home/hcs_analysis/miniconda3 && \
    rm Miniconda3-latest-Linux-x86_64.sh

# Add miniconda to path
ENV PATH=/home/hcs_analysis/miniconda3/bin:$PATH

# Update base conda env with conda-env yaml file
COPY environment.yml /home/hcs_analysis/environment.yml
RUN conda env update -n base -f /home/hcs_analysis/environment.yml
