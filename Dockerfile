FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:0
ENV VNC_PORT=5900
ENV NOVNC_PORT=6080

# Install minimal dependencies
RUN apt update && apt install -y \
    openbox \
    midori \
    tigervnc-standalone-server \
    tigervnc-common \
    novnc \
    websockify \
    x11-xserver-utils \
    dbus-x11 \
    ca-certificates \
    xterm \
    wget \
    unzip \
    && apt clean && rm -rf /var/lib/apt/lists/*

# Create user
RUN useradd -m -s /bin/bash user
USER user
WORKDIR /home/user

# Openbox startup
RUN mkdir -p ~/.config/openbox && \
    echo "exec openbox-session & midori" > ~/.config/openbox/autostart

# VNC startup script
RUN mkdir -p ~/.vnc && \
    echo '#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec openbox-session &' > ~/.vnc/xstartup && \
    chmod +x ~/.vnc/xstartup

# Entry script
USER root
RUN echo '#!/bin/bash
set -e

mkdir -p /home/user/.vnc
echo "$VNC_PASSWORD" | vncpasswd -f > /home/user/.vnc/passwd
chmod 600 /home/user/.vnc/passwd
chown -R user:user /home/user/.vnc

su - user -c "vncserver :0 -geometry 1280x720 -depth 24"

websockify --web=/usr/share/novnc/ --wrap-mode=ignore 0.0.0.0:6080 localhost:5900
' > /entrypoint.sh && chmod +x /entrypoint.sh

EXPOSE 6080
CMD ["/entrypoint.sh"]
