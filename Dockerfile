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

# install android-sdk
RUN dpkg --add-architecture i386 && apt-get install -y --force-yes expect git wget curl libc6-i386 lib32stdc++6 lib32gcc1 lib32ncurses5 lib32z1

# Install libgtk as a separate step so that we can share the layer above with
# the netbeans image
RUN apt-get install -y curl libgtk2.0-0 libcanberra-gtk-module

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN cd /opt && wget --output-document=android-sdk.tgz --quiet http://dl.google.com/android/android-sdk_r24.3.3-linux.tgz && tar xzf android-sdk.tgz && rm -f android-sdk.tgz && chown -R developer.developer android-sdk-linux

# Setup environment
ENV ANDROID_HOME /opt/android-sdk-linux
ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools

# Install sdk elements
COPY tools /opt/tools

RUN chmod +x /opt/tools/android-accept-licenses.sh

ENV PATH ${PATH}:/opt/tools
RUN ["/opt/tools/android-accept-licenses.sh", "android update sdk --all --no-ui --filter platform-tools,tools,build-tools-21,build-tools-21.0.1,build-tools-21.0.2,build-tools-21.1,build-tools-21.1.1,build-tools-21.1.2,build-tools-22,build-tools-22.0.1,android-21,android-22,addon-google_apis_x86-google-21,extra-android-support,extra-android-m2repository,extra-google-m2repository,extra-google-google_play_services,sys-img-armeabi-v7a-android-21"]

RUN which adb
RUN which android

#download android studio and install
RUN  wget 'https://dl.google.com/dl/android/studio/ide-zips/1.3.0.10/android-studio-ide-141.2117773-linux.zip' -O /tmp/studio.zip -q && unzip -d /opt /tmp/studio.zip && rm /tmp/studio.zip

ADD run /usr/local/bin/android_studio

RUN chmod +x /usr/local/bin/android_studio && \
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
