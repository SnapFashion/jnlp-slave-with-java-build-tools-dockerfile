FROM cloudbees/java-build-tools

USER root

# Install docker
RUN apt-get update -y \
    && apt-get -y install \
        apt-transport-https \
        ca-certificates \
        curl \
        software-properties-common \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
    && apt-key fingerprint 0EBFCD88 \
    && add-apt-repository -y \
        "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) \
        stable" \
    && apt-get update -y \
    && apt-get -y install docker-ce

# Install docker-compose
RUN curl -L https://github.com/docker/compose/releases/download/1.19.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose

# Setup root permissions for jenkins user, so it can use the docker socket
RUN rm /etc/sudoers \
    && apt-get update -y \
    && apt-get install -y sudo \
    && rm -rf /lar/lib/lists/*
RUN echo "ALL ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers

ARG JENKINS_REMOTING_VERSION=3.12

# See https://github.com/jenkinsci/docker-slave/blob/2.62/Dockerfile#L32
RUN curl --create-dirs -sSLo /usr/share/jenkins/slave.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/$JENKINS_REMOTING_VERSION/remoting-$JENKINS_REMOTING_VERSION.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/slave.jar

# Install pyenv dependencies
RUN apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev \
        libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
        xz-utils tk-dev

COPY jenkins-slave /usr/local/bin/jenkins-slave

RUN chmod a+rwx /home/jenkins
WORKDIR /home/jenkins
USER jenkins

# Install pyenv
RUN git clone https://github.com/pyenv/pyenv.git ~/.pyenv \
    && echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc \
    && echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc \
    && echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ~/.bashrc
ENV PYENV_ROOT /home/jenkins/.pyenv
ENV PATH /home/jenkins/.pyenv/shims:/home/jenkins/.pyenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN pyenv install 2.7
RUN pyenv install 3.6.3

ENTRYPOINT ["/opt/bin/entry_point.sh", "/usr/local/bin/jenkins-slave"]
