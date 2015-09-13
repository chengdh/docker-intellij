FROM phusion/baseimage:0.9.17
MAINTAINER chengdh "cheng.donghui@gmail.com"

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]
RUN rm -f /etc/service/sshd/down

# Regenerate SSH host keys. baseimage-docker does not contain any, so you
# have to do that yourself. You may also comment out this instruction; the
# init system will auto-generate one during boot.
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh


RUN /usr/sbin/enable_insecure_key

RUN chmod -R 755 /etc/container_environment
RUN chmod 644 /etc/container_environment.sh /etc/container_environment.json


RUN sed 's/main$/main universe/' -i /etc/apt/sources.list && \
    apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository ppa:webupd8team/java -y && \
    apt-get update && \
    echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get install -y oracle-java8-installer libxext-dev libxrender-dev libxtst-dev && \
    apt-get install -y git gradle && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

# Install libgtk as a separate step so that we can share the layer above with
# the netbeans image
RUN apt-get update && apt-get install -y libgtk2.0-0 libcanberra-gtk-module
# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


RUN wget http://download.jetbrains.com/idea/ideaIC-14.1.4.tar.gz -O /tmp/intellij.tar.gz -q && \
    echo 'Installing IntelliJ IDEA' && \
    mkdir -p /opt/intellij && \
    tar -xf /tmp/intellij.tar.gz --strip-components=1 -C /opt/intellij && \
    rm /tmp/intellij.tar.gz

ADD run /usr/local/bin/intellij

RUN chmod +x /usr/local/bin/intellij && \
    mkdir -p /home/developer
#    echo "developer:x:1000:1000:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
#    echo "developer:x:1000:" >> /etc/group && \
#    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
#    chmod 0440 /etc/sudoers.d/developer && \
#    chown developer:developer -R /home/developer && \
#    chown root:root /usr/bin/sudo && chmod 4755 /usr/bin/sudo

USER root
ENV HOME /home/developer
WORKDIR /home/developer
#CMD /usr/local/bin/intellij
CMD ["true"]
