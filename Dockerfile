FROM alpine:3.19

ENV DISPLAY=:0
ENV VNC_PORT=5900
ENV NOVNC_PORT=6080

# --- ENABLE MAIN + COMMUNITY REPOSITORIES ---
RUN echo "https://dl-cdn.alpinelinux.org/alpine/v3.19/main" > /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/v3.19/community" >> /etc/apk/repositories

# --- INSTALL VERIFIED PACKAGES ---
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

# --- CREATE USER ---
RUN adduser -D user
USER user
WORKDIR /home/user

# --- OPENBOX AUTOSTART (LAUNCH BROWSER) ---
RUN mkdir -p ~/.config/openbox && \
    echo "badwolf &" > ~/.config/openbox/autostart

# --- VNC XSTARTUP (SAFE) ---
RUN mkdir -p ~/.vnc && \
    cat << 'EOF' > ~/.vnc/xstartup
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec openbox-session &
EOF
RUN chmod +x ~/.vnc/xstartup

# --- ENTRYPOINT (ALPINE-COMPATIBLE) ---
USER root
RUN cat << 'EOF' > /entrypoint.sh
#!/bin/sh
set -e

# Prepare VNC directory
mkdir -p /home/user/.vnc

# Set VNC password from ENV
echo "$VNC_PASSWORD" | vncpasswd -f > /home/user/.vnc/passwd
chmod 600 /home/user/.vnc/passwd

# VNC config (NO FLAGS ON ALPINE)
cat << 'CFG' > /home/user/.vnc/config
geometry=1280x720
depth=24
localhost=no
CFG

chown -R user:user /home/user/.vnc

# Start VNC server (flags NOT supported on Alpine)
su user -c "vncserver :0"

# Start noVNC
websockify --web=/usr/share/novnc/ 0.0.0.0:6080 localhost:5900
EOF
RUN chmod +x /entrypoint.sh

EXPOSE 6080
CMD ["/entrypoint.sh"]
