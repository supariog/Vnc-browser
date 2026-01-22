FROM alpine:3.19

ENV DISPLAY=:0
ENV VNC_PORT=5900
ENV NOVNC_PORT=6080

# Enable main + community repos
RUN echo "https://dl-cdn.alpinelinux.org/alpine/v3.19/main" > /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/v3.19/community" >> /etc/apk/repositories

# Install packages (VERIFIED)
RUN apk update && apk add --no-cache \
    openbox \
    tigervnc \
    xauth \
    novnc \
    websockify \
    badwolf \
    xterm \
    dbus \
    bash \
    ca-certificates

# Create user
RUN adduser -D user
USER user
WORKDIR /home/user

# Openbox autostart
RUN mkdir -p ~/.config/openbox && \
    echo "badwolf &" > ~/.config/openbox/autostart

# VNC xstartup
RUN mkdir -p ~/.vnc && \
    cat << 'EOF' > ~/.vnc/xstartup
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec openbox-session &
EOF
RUN chmod +x ~/.vnc/xstartup

# Entrypoint
USER root
RUN cat << 'EOF' > /entrypoint.sh
#!/bin/sh
set -e

mkdir -p /home/user/.vnc

echo "$VNC_PASSWORD" | vncpasswd -f > /home/user/.vnc/passwd
chmod 600 /home/user/.vnc/passwd
chown -R user:user /home/user/.vnc

su user -c "vncserver :0 -localhost no -geometry 1280x720 -depth 24"

websockify --web=/usr/share/novnc/ 0.0.0.0:6080 localhost:5900
EOF
RUN chmod +x /entrypoint.sh

EXPOSE 6080
CMD ["/entrypoint.sh"]
