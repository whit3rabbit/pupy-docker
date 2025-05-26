# Use an official Python 3.10 slim image based on Debian Buster
FROM python:3.10-slim-buster AS builder

# **** Set ARG Values ****
ARG PUPY_USER=pupy
ARG PUPY_UID=1000
ARG PUPY_GID=1000
ARG PUPY_HOME=/opt/pupy

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# ********** Installing System Dependencies ***************
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    wget curl sudo nano git build-essential pkg-config python3-dev locales cython \
    libssl-dev libffi-dev openssh-client sslh libcap2-bin john vim-tiny \
    less osslsigncode nmap net-tools libmagic-dev swig autoconf automake \
    unzip libtool ncurses-term tcpdump libpam-dev fuse libuv1-dev libfuse2 \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set up locale
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Upgrade pip and install common Python build tools globally as root
RUN python -m pip install --no-cache-dir --upgrade pip setuptools wheel six

# Copy your pinned requirements.txt to a temporary location
COPY pinned-requirements.txt /tmp/pinned-requirements.txt

# Install Python Requirements from the pinned file globally as root
RUN python -m pip uninstall -y pycrypto pycryptodome pyOpenSSL cryptography || true && \
    python -m pip install --no-cache-dir -r /tmp/pinned-requirements.txt && \
    rm /tmp/pinned-requirements.txt

# ********** Pupy User and Directory Setup (as root) **************
RUN groupadd -g ${PUPY_GID} ${PUPY_USER} || true \
    && useradd -m -s /bin/bash -u ${PUPY_UID} -g ${PUPY_GID} ${PUPY_USER} || true \
    && mkdir -p ${PUPY_HOME} \
    && chown -R ${PUPY_USER}:${PUPY_USER} ${PUPY_HOME} /home/${PUPY_USER}

# Switch to Pupy User for subsequent operations
USER ${PUPY_USER}
WORKDIR ${PUPY_HOME}

# Clone Pupy Repository and its submodules
RUN git clone --recursive --depth 1 --branch nextgen https://github.com/n1nj4sec/pupy . \
    && git submodule update --init --recursive --depth 1

# Create directories that Pupy might expect
RUN mkdir -p ${PUPY_HOME}/pupy/payload_templates \
    && mkdir -p ${PUPY_HOME}/pupy/data \
    && mkdir -p /home/${PUPY_USER}/.config/pupy/ \
    && mkdir -p ${PUPY_HOME}/output \
    && mkdir -p ${PUPY_HOME}/config

# Download precompiled payload templates and rename to include -310 suffix
RUN echo "Downloading Pupy precompiled payload templates..." && \
    curl -L -s -o ${PUPY_HOME}/pupy/payload_templates/pupyx64-310.dll "https://gitlab-student.centralesupelec.fr/bastien.le-guern/secef-apt29/-/raw/master/secef-pupy/pupy/payload_templates/pupyx64.dll" && \
    curl -L -s -o ${PUPY_HOME}/pupy/payload_templates/pupyx64-310.exe "https://gitlab-student.centralesupelec.fr/bastien.le-guern/secef-apt29/-/raw/master/secef-pupy/pupy/payload_templates/pupyx64.exe" && \
    curl -L -s -o ${PUPY_HOME}/pupy/payload_templates/pupyx64-310.lin "https://gitlab-student.centralesupelec.fr/bastien.le-guern/secef-apt29/-/raw/master/secef-pupy/pupy/payload_templates/pupyx64.lin" && \
    curl -L -s -o ${PUPY_HOME}/pupy/payload_templates/pupyx64-310.lin.so "https://gitlab-student.centralesupelec.fr/bastien.le-guern/secef-apt29/-/raw/master/secef-pupy/pupy/payload_templates/pupyx64.lin.so" && \
    curl -L -s -o ${PUPY_HOME}/pupy/payload_templates/pupyx64d-310.dll "https://gitlab-student.centralesupelec.fr/bastien.le-guern/secef-apt29/-/raw/master/secef-pupy/pupy/payload_templates/pupyx64d.dll" && \
    curl -L -s -o ${PUPY_HOME}/pupy/payload_templates/pupyx64d-310.exe "https://gitlab-student.centralesupelec.fr/bastien.le-guern/secef-apt29/-/raw/master/secef-pupy/pupy/payload_templates/pupyx64d.exe" && \
    curl -L -s -o ${PUPY_HOME}/pupy/payload_templates/pupyx64d-310.lin "https://gitlab-student.centralesupelec.fr/bastien.le-guern/secef-apt29/-/raw/master/secef-pupy/pupy/payload_templates/pupyx64d.lin" && \
    curl -L -s -o ${PUPY_HOME}/pupy/payload_templates/pupyx64d-310.lin.so "https://gitlab-student.centralesupelec.fr/bastien.le-guern/secef-apt29/-/raw/master/secef-pupy/pupy/payload_templates/pupyx64d.lin.so" && \
    curl -L -s -o ${PUPY_HOME}/pupy/payload_templates/pupyx86-310.dll "https://gitlab-student.centralesupelec.fr/bastien.le-guern/secef-apt29/-/raw/master/secef-pupy/pupy/payload_templates/pupyx86.dll" && \
    curl -L -s -o ${PUPY_HOME}/pupy/payload_templates/pupyx86-310.exe "https://gitlab-student.centralesupelec.fr/bastien.le-guern/secef-apt29/-/raw/master/secef-pupy/pupy/payload_templates/pupyx86.exe" && \
    curl -L -s -o ${PUPY_HOME}/pupy/payload_templates/pupyx86-310.lin "https://gitlab-student.centralesupelec.fr/bastien.le-guern/secef-apt29/-/raw/master/secef-pupy/pupy/payload_templates/pupyx86.lin" && \
    curl -L -s -o ${PUPY_HOME}/pupy/payload_templates/pupyx86-310.lin.so "https://gitlab-student.centralesupelec.fr/bastien.le-guern/secef-apt29/-/raw/master/secef-pupy/pupy/payload_templates/pupyx86.lin.so" && \
    curl -L -s -o ${PUPY_HOME}/pupy/payload_templates/pupyx86d-310.dll "https://gitlab-student.centralesupelec.fr/bastien.le-guern/secef-apt29/-/raw/master/secef-pupy/pupy/payload_templates/pupyx86d.dll" && \
    curl -L -s -o ${PUPY_HOME}/pupy/payload_templates/pupyx86d-310.exe "https://gitlab-student.centralesupelec.fr/bastien.le-guern/secef-apt29/-/raw/master/secef-pupy/pupy/payload_templates/pupyx86d.exe" && \
    curl -L -s -o ${PUPY_HOME}/pupy/payload_templates/pupyx86d-310.lin "https://gitlab-student.centralesupelec.fr/bastien.le-guern/secef-apt29/-/raw/master/secef-pupy/pupy/payload_templates/pupyx86d.lin" && \
    curl -L -s -o ${PUPY_HOME}/pupy/payload_templates/pupyx86d-310.lin.so "https://gitlab-student.centralesupelec.fr/bastien.le-guern/secef-apt29/-/raw/master/secef-pupy/pupy/payload_templates/pupyx86d.lin.so" && \
    curl -L -s -o ${PUPY_HOME}/pupy/payload_templates/linux-amd64.zip "https://gitlab-student.centralesupelec.fr/bastien.le-guern/secef-apt29/-/raw/master/secef-pupy/pupy/payload_templates/linux-amd64.zip" && \
    curl -L -s -o ${PUPY_HOME}/pupy/payload_templates/linux-x86.zip "https://gitlab-student.centralesupelec.fr/bastien.le-guern/secef-apt29/-/raw/master/secef-pupy/pupy/payload_templates/linux-x86.zip" && \
    curl -L -s -o ${PUPY_HOME}/pupy/payload_templates/windows-amd64.zip "https://gitlab-student.centralesupelec.fr/bastien.le-guern/secef-apt29/-/raw/master/secef-pupy/pupy/payload_templates/windows-amd64.zip" && \
    curl -L -s -o ${PUPY_HOME}/pupy/payload_templates/windows-x86.zip "https://gitlab-student.centralesupelec.fr/bastien.le-guern/secef-apt29/-/raw/master/secef-pupy/pupy/payload_templates/windows-x86.zip" && \
    echo "Finished downloading Pupy precompiled payload templates."

# Copy default config file
RUN cp ${PUPY_HOME}/pupy/conf/pupy.conf.default /home/${PUPY_USER}/.config/pupy/pupy.conf

# Switch back to root for system-level modifications
USER root

# Download Mimikatz as example payload
RUN mkdir -p /opt/mimikatz \
    && wget https://github.com/gentilkiwi/mimikatz/releases/download/2.2.0-20220919/mimikatz_trunk.zip -O /opt/mimikatz/mimikatz.zip \
    && unzip /opt/mimikatz/mimikatz.zip -d /opt/mimikatz/ \
    && rm /opt/mimikatz/mimikatz.zip \
    && chown -R ${PUPY_USER}:${PUPY_USER} /opt/mimikatz

# tcpdump permissions
RUN if [ -f /usr/sbin/tcpdump ]; then chmod +s /usr/sbin/tcpdump; fi

# Create entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Final chown
RUN chown -R ${PUPY_USER}:${PUPY_USER} ${PUPY_HOME}

# Switch back to Pupy User for runtime
USER ${PUPY_USER}
WORKDIR ${PUPY_HOME}

# Add Pupy project root to PYTHONPATH
ENV PYTHONPATH="${PUPY_HOME}"

# Define volumes for configuration and output
VOLUME ["${PUPY_HOME}/config", "${PUPY_HOME}/output"]

# Expose default Pupy ports
EXPOSE 443 80 8443 9090 9091 1234 1235 8080 8081 9000

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Default command is pupysh
CMD ["pupysh"]