FROM alpine:3.19

ENV DISPLAY=:0
ENV VNC_PORT=5900
ENV NOVNC_PORT=6080

# Enable repositories
RUN sed -i 's/#http/http/g' /etc/apk/repositories && apk update

# Install packages
RUN apk add --no-cache \
    xvfb \
    x11vnc \
    openbox \
    badwolf \
    novnc \
    websockify \
    dbus \
    bash \
    ttf-dejavu

# Prepare VNC directory
RUN mkdir -p /root/.vnc

# Startup script
RUN cat << 'EOF' > /start.sh
#!/bin/sh
set -e

# Create VNC password
if [ -z "$VNC_PASSWORD" ]; then
  echo "VNC_PASSWORD not set"
  exit 1
fi

x11vnc -storepasswd "$VNC_PASSWORD" /root/.vnc/passwd

# Start X virtual framebuffer
Xvfb :0 -screen 0 1280x720x24 &
sleep 2

# Start Openbox
openbox-session &
sleep 2

# Start Badwolf (sandbox disabled)
badwolf --no-sandbox https://www.instagram.com &
sleep 2

# Start VNC server (WITH password)
x11vnc -display :0 \
  -rfbauth /root/.vnc/passwd \
  -forever -shared -localhost no &
sleep 2

# Start noVNC
websockify \
  --web=/usr/share/novnc/ \
  0.0.0.0:$NOVNC_PORT localhost:$VNC_PORT
EOF

RUN chmod +x /start.sh

EXPOSE 6080

CMD ["/start.sh"]
