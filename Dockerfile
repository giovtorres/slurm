FROM rockylinux:9

LABEL org.opencontainers.image.source="https://github.com/giovtorres/slurm-docker" \
      org.opencontainers.image.url="https://github.com/giovtorres/slurm-docker" \
      org.opencontainers.image.title="slurm-docker" \
      org.opencontainers.image.license="MIT" \
      org.opencontainers.image.authors="Giovanni Torres and contributors" \
      org.opencontainers.image.description="[Unofficial] Slurm in Docker"

# Install dependencies
RUN set -ex \
    && dnf upgrade --refresh --assumeyes \
    && dnf install --assumeyes epel-release \
    && dnf config-manager --set-enable devel \
    && dnf -y install \
        autoconf \
        bash-completion \
        bzip2 \
        bzip2-devel \
        dbus-devel \
        file \
        iproute \
        gcc \
        gcc-c++ \
        gdbm-devel \
        git \
        glibc-devel \
        gmp-devel \
        hdf5-devel \
        http-parser-devel \
        hwloc-devel \
        json-c-devel \
        libcurl-devel \
        libffi-devel \
        libGL-devel \
        libjwt-devel \
        librdkafka-devel \
        libyaml-devel \
        libX11-devel \
        lua-devel \
        lz4-devel \
        make \
        mariadb-server \
        mariadb-devel \
        munge \
        munge-devel \
        ncurses-devel \
        openssl-devel \
        pam-devel \
        patch \
        perl-core \
        pkgconfig \
        psmisc \
        readline-devel \
        s2n-tls-devel \
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

# Install and Use pyenv inside the container to switch between Python versions.
ARG PYTHON_VERSIONS="3.9 3.10 3.11 3.12 3.13"
ENV PYENV_ROOT="${HOME}/.pyenv"
ENV PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"
RUN set -ex -o pipefail \
    && curl https://pyenv.run | bash \
    && echo 'eval "$(pyenv init -)"' >> "${HOME}/.bashrc" \
    && source "${HOME}/.bashrc" \
    && pyenv update

# Copy Python installation script
COPY install_python.sh /tmp/
RUN chmod +x /tmp/install_python.sh

# Install each Python version in its own layer
RUN /tmp/install_python.sh 3.9
RUN /tmp/install_python.sh 3.10
RUN /tmp/install_python.sh 3.11
RUN /tmp/install_python.sh 3.12
RUN /tmp/install_python.sh 3.13

ARG SLURM_TAG=slurm-24-05-3-1
ARG JOBS=2
RUN set -ex \
    && git clone -b ${SLURM_TAG} --single-branch --depth=1 https://github.com/SchedMD/slurm.git \
    && pushd slurm \
    && ./configure \
        --prefix=/usr \
        --libdir=/usr/lib64 \
        --sysconfdir=/etc/slurm \
        --enable-slurmrestd \
        --enable-multiple-slurmd \
        --enable-debug \
        --with-mysql_config=/usr/bin \
    && make -j ${JOBS} install \
    && install -D -m644 etc/cgroup.conf.example /etc/slurm/cgroup.conf.example \
    && install -D -m644 etc/slurm.conf.example /etc/slurm/slurm.conf.example \
    && install -D -m600 etc/slurmdbd.conf.example /etc/slurm/slurmdbd.conf.example \
    && install -D -m644 contribs/slurm_completion_help/slurm_completion.sh /etc/profile.d/slurm_completion.sh \
    && popd \
    && rm -rf slurm \
    && groupadd -r slurm  \
    && useradd -r -g slurm slurm \
    && mkdir -p /etc/sysconfig/slurm \
        /var/lib/slurmd \
        /var/log/slurm \
        /var/run/slurm \
        /var/spool/slurmctld \
        /var/spool/slurmd \
    && chown -R slurm:slurm /var/*/slurm* \
    && /sbin/create-munge-key

# Mark externally mounted volumes
VOLUME ["/var/lib/mysql", "/var/lib/slurmd", "/var/spool/slurm", "/var/log/slurm"]

# COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# ENTRYPOINT ["/tini", "--", "/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]
