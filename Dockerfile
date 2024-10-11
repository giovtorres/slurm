FROM rockylinux:9

LABEL org.opencontainers.image.source="https://github.com/giovtorres/slurm-docker" \
      org.opencontainers.image.url="https://github.com/giovtorres/slurm-docker" \
      org.opencontainers.image.title="slurm-docker" \
      org.opencontainers.image.license="MIT" \
      org.opencontainers.image.authors="Giovanni Torres and contributors" \
      org.opencontainers.image.description="[Unofficial] Slurm in Docker"

RUN set -ex \
    && yum makecache \
    && yum -y update \
    && yum -y install epel-release \
    && yum -y install \
        autoconf \
        bash-completion \
        bzip2 \
        bzip2-devel \
        file \
        iproute \
        gcc \
        gcc-c++ \
        # gdbm-libs \
        git \
        glibc-devel \
        gmp-devel \
        http-parser \
        json-c \
        libffi-devel \
        libGL-devel \
        libjwt-devel \
        # libyaml-devel \
        libX11-devel \
        make \
        mariadb-server \
        munge \
        munge-libs \
        ncurses-devel \
        openssl-devel \
        patch \
        perl-core \
        pkgconfig \
        psmisc \
        readline-devel \
        sqlite-devel \
        tcl-devel \
        tk \
        tk-devel \
        supervisor \
        wget \
        which \
        vim-enhanced \
        xz-devel \
        zlib-devel \
    && yum clean all \
    && rm -rf /var/cache/yum

# Set Vim and Git defaults
RUN set -ex \
&& echo "syntax on"           >> "$HOME/.vimrc" \
&& echo "set tabstop=4"       >> "$HOME/.vimrc" \
&& echo "set softtabstop=4"   >> "$HOME/.vimrc" \
&& echo "set shiftwidth=4"    >> "$HOME/.vimrc" \
&& echo "set expandtab"       >> "$HOME/.vimrc" \
&& echo "set autoindent"      >> "$HOME/.vimrc" \
&& echo "set fileformat=unix" >> "$HOME/.vimrc" \
&& echo "set encoding=utf-8"  >> "$HOME/.vimrc" \
&& git config --global color.ui auto \
&& git config --global push.default simple

# Add Tini
ARG TINI_VERSION="v0.19.0"
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini.asc /tini.asc
RUN gpg --batch --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 \
 && gpg --batch --verify /tini.asc /tini
RUN chmod +x /tini

# Use pyenv inside the container to switch between Python versions.
ARG PYTHON_VERSIONS="3.9 3.10 3.11 3.12 3.13"
ENV PYENV_ROOT="${HOME}/.pyenv"
ENV PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"

# Install pyenv
RUN set -ex -o pipefail \
    && curl https://pyenv.run | bash \
    && echo 'eval "$(pyenv init -)"' >> "${HOME}/.bashrc" \
    && source "${HOME}/.bashrc" \
    && pyenv update

# Copy installation script
COPY install_python.sh /tmp/
RUN chmod +x /tmp/install_python.sh

# Install each Python version in its own layer
RUN /tmp/install_python.sh 3.9
RUN /tmp/install_python.sh 3.10
RUN /tmp/install_python.sh 3.11
RUN /tmp/install_python.sh 3.12
RUN /tmp/install_python.sh 3.13

# Mark externally mounted volumes
VOLUME ["/var/lib/mysql", "/var/lib/slurmd", "/var/spool/slurm", "/var/log/slurm"]

# COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# ENTRYPOINT ["/tini", "--", "/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]
