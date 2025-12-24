ARG PG_VERSION
ARG PLPGSQL_CHECK_VERSION

FROM postgres:${PG_VERSION}-bullseye

ARG PG_VERSION
ARG PLPGSQL_CHECK_VERSION

SHELL ["/bin/bash", "-c"]
RUN echo 'alias ll="ls -l"' >> /root/.bashrc && \
    echo 'export PS1="\[\033[1;36m\][\u@\h \W]\[\033[0;31m\]$\[\033[0;37m\] "' >> /root/.bashrc

# install dependency
RUN apt-get update && \
    apt-get install -y make gcc wget unzip postgresql-server-dev-${PG_VERSION}

# build plpgsql_check
WORKDIR /opt/
RUN wget https://github.com/okbob/plpgsql_check/archive/refs/tags/v${PLPGSQL_CHECK_VERSION}.zip
RUN unzip v${PLPGSQL_CHECK_VERSION}.zip
WORKDIR /opt/plpgsql_check-${PLPGSQL_CHECK_VERSION}/
RUN make -j4 USE_PGXS=1 install
