FROM ubuntu:20.04

ARG HOST_GID
ARG HOST_UID

# Устанавливаем переменные окружения
ENV LC_CTYPE=C.UTF-8
ARG DEBIAN_FRONTEND=noninteractive
ENV HOST_GID=$HOST_GID
ENV HOST_UID=$HOST_UID

#--------------AFL---------------
# Устанавливаем зависимости и AFL++
RUN apt-get update && \
    apt-get install -y build-essential python3-dev tmux vim automake cmake git flex bison libglib2.0-dev libpixman-1-dev \ 
            python3-setuptools cargo libgtk-3-dev wget curl lld llvm llvm-dev clang

RUN apt-get install -y gcc-$(gcc --version|head -n1|sed 's/\..*//'|sed 's/.* //')-plugin-dev \ 
        libstdc++-$(gcc --version|head -n1|sed 's/\..*//'|sed 's/.* //')-dev

# Устанавливаем AFL++
WORKDIR /tmp
RUN git clone https://github.com/AFLplusplus/AFLplusplus && cd AFLplusplus && make distrib NO_NYX=1 NO_QEMU=1 && make install

#--------------PVS---------------
# Устанавливаем PVS-Studio
RUN wget -q -O - https://files.pvs-studio.com/etc/pubkey.txt | apt-key add - \
 && wget -O /etc/apt/sources.list.d/viva64.list \
    https://files.pvs-studio.com/etc/viva64.list \
 && apt update -yq \
 && apt install -yq pvs-studio strace \
 && pvs-studio --version \
 && apt clean -yq
RUN pvs-studio-analyzer credentials PVS-Studio Free FREE-FREE-FREE-FREE

# --------------IPTABLES--------------
# Устанавливаем зависимости для iptables
RUN apt-get install -y \
    build-essential \
    wget \
    autoconf \
    automake \
    libtool \
    pkg-config \
    bison \
    flex \
    libnfnetlink-dev \
    libmnl-dev \
    libnftnl-dev \
    libpcap-dev 

WORKDIR /root
RUN wget https://www.netfilter.org/projects/iptables/files/iptables-1.8.2.tar.bz2 && \
    tar -xvjf iptables-1.8.2.tar.bz2
# Сборка не AFL-компилятором
WORKDIR /root/iptables-1.8.2
RUN ./configure --prefix=/root/iptables/install --sysconfdir=/root/iptables/install/etc/ --disable-nftables && \
    make && \
    make install

# Сборка AFL-компилятором
RUN CC=afl-gcc-fast CFLAGS="-fsanitize=address -fno-omit-frame-pointer" ./configure --prefix=/root/iptables/afl-install --sysconfdir=/root/iptables/afl-install/etc/ --disable-nftables && \
    make && \
    make install

RUN groupadd -g $HOST_GID hostgroup && \
    useradd -u $HOST_UID -g hostgroup afl

# Настройка окружения 
RUN echo 'export PS1="\[\e]0;\u@\h: \w\a\]\[\033[01;31m\]\u\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]# "' >> /root/.bashrc
#	echo 'export PS1="\[\e]0;\u@\h: \w\a\]\[\033[01;31m\]\u\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]# "' >> /home/afl/.bashrc && \

WORKDIR /pwd
# USER afl
CMD ["tail", "-f", "/dev/null"]
