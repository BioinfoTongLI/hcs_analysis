FROM rapidsai/miniforge-cuda:cuda11.8.0-base-ubuntu22.04-py3.9

# Install update apt and install wget package
RUN apt-get update && apt-get clean && \
    apt-get install -y libtiff5 git

# Update base conda env with conda-env yaml file
COPY environment.yml /home/hcs_analysis/environment.yml
RUN conda env update -n base -f /home/hcs_analysis/environment.yml
 
WORKDIR /opt

# Installing from source, because this PR is not in the latest release yet (v0.6.2)
# https://github.com/peng-lab/BaSiCPy/commit/d2f4b9fe03efdd6e1bc413d1f9f4340e5d3c2c6a
RUN cd /opt && \
    git clone https://github.com/peng-lab/BaSiCPy.git && \
    cd BaSiCPy && \
    git checkout dev && \
    pip install .

# Downgrade to 0.4.23 for BaSiCPy-GPU compatibility
RUN pip install --upgrade jax==0.4.23 "jax[cuda11_pip]==0.4.23" -f https://storage.googleapis.com/jax-releases/jax_cuda_releases.html

RUN pip install git+https://github.com/jluethi/fractal-helper-tasks.git

RUN pip install cellpose==2.3.2

RUN cd /opt && \
    git clone https://github.com/fmi-basel/gliberal-scMultipleX.git && \
    cd gliberal-scMultipleX && \
    pip install ".[fractal-tasks]"

RUN chmod -R 777 /opt

ENV NUMBA_CACHE_DIR=/tmp

# Create user analysis
# RUN useradd -m hcs_analysis

# switch user to analysis
# USER hcs_analysis
