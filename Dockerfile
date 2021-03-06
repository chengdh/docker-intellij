FROM phusion/baseimage:0.9.17
MAINTAINER chengdh "cheng.donghui@gmail.com"

# Use baseimage-docker's init system.
RUN sudo rm -f /etc/service/sshd/down

RUN sed 's/main$/main universe/' -i /etc/apt/sources.list && \
    apt-get update && apt-get install -y software-properties-common xauth && \
    add-apt-repository ppa:webupd8team/java -y && \
    apt-get update && \
    echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get install -y oracle-java8-installer libxext-dev libxrender-dev libxtst-dev && \
    apt-get install -y git gradle

# Install libgtk as a separate step so that we can share the layer above with
# the netbeans image
RUN apt-get install -y libgtk2.0-0 libcanberra-gtk-module
# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


RUN wget http://download.jetbrains.com/idea/ideaIC-14.1.4.tar.gz -O /tmp/intellij.tar.gz -q && \
    echo 'Installing IntelliJ IDEA' && \
    mkdir -p /opt/intellij && \
    tar -xf /tmp/intellij.tar.gz --strip-components=1 -C /opt/intellij && \
    rm /tmp/intellij.tar.gz

ADD run /usr/local/bin/intellij

RUN chmod +x /usr/local/bin/intellij && \
    mkdir -p /home/developer && \
    echo "developer:x:1000:1000:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
    echo "developer:x:1000:" >> /etc/group && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    chown developer:developer -R /home/developer && \
    chown root:root /usr/bin/sudo && chmod 4755 /usr/bin/sudo

# Regenerate SSH host keys. baseimage-docker does not contain any, so you
# have to do that yourself. You may also comment out this instruction; the
# init system will auto-generate one during boot.
RUN sudo /etc/my_init.d/00_regen_ssh_host_keys.sh

#添加ssh key
ADD enable_security_key_developer /usr/local/bin/enable_security_key_developer

RUN chmod +x /usr/local/bin/enable_security_key_developer

RUN /usr/local/bin/enable_security_key_developer

USER developer
ENV HOME /home/developer
WORKDIR /home/developer
