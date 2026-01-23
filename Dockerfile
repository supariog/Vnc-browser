FROM alpine:3.19

ENV DISPLAY=:0
ENV NOVNC_PORT=6080

# Enable repos
RUN echo "https://dl-cdn.alpinelinux.org/alpine/v3.19/main" > /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/v3.19/community" >> /etc/apk/repositories

# Install packages (VERIFIED)
RUN apk update && apk add --no-cache \
    openbox \
    x11vnc \
    xvfb \
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

# xstartup
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

# Start virtual X display
Xvfb :0 -screen 0 1280x720x24 &

# VNC password
mkdir -p /home/user/.vnc
x11vnc -storepasswd "$VNC_PASSWORD" /home/user/.vnc/passwd
chown -R user:user /home/user/.vnc

# Start desktop
su user -c "DISPLAY=:0 ~/.vnc/xstartup &"

# Start x11vnc (NO BLACKLISTING)
x11vnc -display :0 \
  -rfbauth /home/user/.vnc/passwd \
  -forever \
  -shared \
  -nopw &

# Start noVNC
websockify --web=/usr/share/novnc/ 0.0.0.0:6080 localhost:5900
EOF
RUN chmod +x /entrypoint.sh

EXPOSE 6080
CMD ["/entrypoint.sh"]
