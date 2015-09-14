# Copyright (c) Jupyter Development Team.
FROM   ubuntu:14.04
MAINTAINER Mark McCahill "mark.mccahill@duke.edu"

USER root

# Install all OS dependencies for fully functional notebook server
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -yq --no-install-recommends \
    git \
    vim \
    wget \
    build-essential \
    python-dev \
    ca-certificates \
    bzip2 \
    unzip \
    libsm6 \
    pandoc \
    texlive-latex-base \
    texlive-latex-extra \
    texlive-fonts-extra \
    texlive-fonts-recommended \
    supervisor \
    sudo \
    && apt-get clean

# Configure environment
ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH
ENV NB_USER jovyan
ENV NB_UID 1000

# Install conda
RUN mkdir -p $CONDA_DIR && \
    echo export PATH=$CONDA_DIR/bin:'$PATH' > /etc/profile.d/conda.sh && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-3.9.1-Linux-x86_64.sh && \
    /bin/bash /Miniconda3-3.9.1-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Miniconda3-3.9.1-Linux-x86_64.sh && \
    $CONDA_DIR/bin/conda install --yes conda==3.14.1

# Install Jupyter notebook
RUN conda install --yes \
    'notebook=4.0*' \
    terminado \
    && conda clean -yt

# Create jovyan user with UID=1000 and in the 'users' group
# Grant ownership over the conda dir and home dir, but stick the group as root.
RUN useradd -m -s /bin/bash -N -u $NB_UID $NB_USER && \
    mkdir /home/$NB_USER/work && \
    mkdir /home/$NB_USER/.jupyter && \
    mkdir /home/$NB_USER/.local && \
    chown -R $NB_USER:users $CONDA_DIR && \
    chown -R $NB_USER:users /home/$NB_USER

# add bash kernel for the user jovyan
USER jovyan
RUN pip install  bash_kernel
RUN python -m bash_kernel.install
USER root

# mysql client so we can connect to an SQL server from bash shell
RUN apt-get install -y mysql-client

# python notebook support for sql
RUN apt-get install -y python-mysqldb python-dev libmysqlclient-dev build-essential
RUN pip install mysqlclient
RUN git clone https://github.com/mccahill/ipython-sql.git; \
    cd ipython-sql; \
    python setup.py install; \
    rm /ipython-sql ; \
    cd /
#RUN pip install ipython-sql

# Configure container startup
EXPOSE 8888
CMD [ "start-notebook.sh" ]

# Add local files as late as possible to avoid cache busting
COPY start-notebook.sh /usr/local/bin/
COPY notebook.conf /etc/supervisor/conf.d/
COPY jupyter_notebook_config.py /home/$NB_USER/.jupyter/
RUN chown -R $NB_USER:users /home/$NB_USER/.jupyter
