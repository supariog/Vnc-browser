FROM alpine:3.19

ENV DISPLAY=:0
ENV VNC_PORT=5900
ENV NOVNC_PORT=6080

RUN sed -i 's/#http/http/g' /etc/apk/repositories && apk update

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

RUN mkdir -p /root/.vnc

RUN cat << 'EOF' > /start.sh
#!/bin/sh
set -e

if [ -z "$VNC_PASSWORD" ]; then
  echo "VNC_PASSWORD not set"
  exit 1
fi

# Create VNC password
x11vnc -storepasswd "$VNC_PASSWORD" /root/.vnc/passwd

# Start virtual display
Xvfb :0 -screen 0 1280x720x24 &
sleep 2

# Start window manager
openbox-session &
sleep 2

# Start browser (sandbox disabled)
badwolf --no-sandbox https://www.instagram.com &
sleep 2

# Start VNC server (CORRECT FLAGS)
x11vnc \
  -display :0 \
  -rfbauth /root/.vnc/passwd \
  -forever \
  -shared \
  -rfbport 5900 &
sleep 2

# Start noVNC
websockify \
  --web=/usr/share/novnc/ \
  0.0.0.0:$NOVNC_PORT localhost:$VNC_PORT
EOF

RUN chmod +x /start.sh

EXPOSE 6080

CMD ["/start.sh"]
