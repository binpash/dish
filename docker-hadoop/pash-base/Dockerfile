FROM ubuntu:18.04
ARG RELEASE=latest

RUN apt-get update -y && apt-get update --fix-missing
## Note: Even though PaSh's distro-deps.sh should understand whether we are in docker
##       and not need sudo, it doesn't in this case.
RUN apt-get install -y git vim iputils-ping sudo
ENV PASH_HOST="docker"
ENV DISH_TOP="/opt/dish"
ENV PASH_TOP="${DISH_TOP}/pash"
# download PaSh
RUN git clone https://github.com/binpash/dish.git /opt/dish --recursive
# install PaSh and setup shell paths
RUN bash ${PASH_TOP}/scripts/distro-deps.sh
RUN yes | bash ${PASH_TOP}/scripts/setup-pash.sh
RUN yes | bash ${DISH_TOP}/scripts/setup-dish.sh

RUN if [ "$RELEASE" = "eval" ]; then \
    apt-get update && cd ${DISH_TOP}/evaluation/distr_benchmarks && ./install_all_deps.sh; \
    fi

# append for unicode issues
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_COLLATE C
