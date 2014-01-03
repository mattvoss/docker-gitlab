FROM ubuntu:12.04
MAINTAINER voss.matthew@gmail.com

RUN sed 's/main$/main universe/' -i /etc/apt/sources.list
RUN apt-get update && apt-get upgrade -y && apt-get clean # 20130925

RUN apt-get install -y wget curl unzip build-essential checkinstall zlib1g-dev libyaml-dev libssl-dev telnet less \
    libgdbm-dev libreadline-dev libncurses5-dev libffi-dev iputils-ping iputils-tracepath rsyslog && \
    apt-get clean

RUN apt-get install -y python-software-properties && \
    add-apt-repository -y ppa:git-core/ppa && \
    apt-get update && apt-get install -y libxml2-dev libxslt-dev libcurl4-openssl-dev libicu-dev libmysqlclient-dev \
    sudo nginx redis-server git git-core openssh-server python2.7 python-docutils postfix logrotate supervisor vim && \
    apt-get clean

RUN wget ftp://ftp.ruby-lang.org/pub/ruby/2.0/ruby-2.0.0-p353.tar.gz -O - | tar -zxf - -C /tmp/ && \
    cd /tmp/ruby-2.0.0-p353/ && \
    ./configure --disable-install-rdoc --enable-pthread --prefix=/usr && \
    make && make install && \
    cd /tmp && rm -rf /tmp/ruby-2.0.0-p353 && \
    gem install --no-ri --no-rdoc bundler

RUN dpkg-divert --local --rename --add /sbin/initctl && \
    ln -s /bin/true /sbin/initctl

RUN echo "*.* @172.17.42.1:514" >> /etc/rsyslog.d/90-networking.conf

ADD resources/ /gitlab/

RUN chmod ugo+rw /dev/null

RUN useradd -m -c Gitlab,,,, git

RUN chmod 755 /gitlab/gitlab && cd /home/git

RUN chown -R git /home/git

ADD resources/nginx-gitlab.conf /etc/nginx/sites-available/gitlab
RUN ln -s /etc/nginx/sites-available/gitlab /etc/nginx/sites-enabled/gitlab

RUN git clone https://github.com/gitlabhq/gitlab-shell.git -b v1.8.0 /home/git/gitlab-shell && \
    git clone https://github.com/gitlabhq/gitlabhq.git -b 6-4-stable /home/git/gitlab && \
    chown -R git /home/git && mkdir /home/git/gitlab/public/assets && chown -R git /home/git/gitlab/public/assets


RUN chmod 755 /gitlab/setup/install && /gitlab/setup/install

ADD resources/authorized_keys /root/.ssh/
RUN chmod 700 /root/.ssh && chmod 600 /root/.ssh/authorized_keys && chown root:root -R /root/.ssh

EXPOSE 22
EXPOSE 80

ENTRYPOINT ["/gitlab/gitlab"]
CMD ["app:start"]
