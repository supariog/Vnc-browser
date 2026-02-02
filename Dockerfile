FROM alpine:3.19

ENV DISPLAY=:1
ENV VNC_PORT=5901
ENV NOVNC_PORT=6080

RUN sed -i 's/#http/http/g' /etc/apk/repositories && apk update

RUN apk add --no-cache \
    xvfb \
    x11vnc \
    openbox \
    badwolf \
    novnc \
    websockify \
    bash \
    ttf-dejavu

RUN mkdir -p /root/.vnc

RUN cat << 'EOF' > /start.sh
#!/bin/sh
set -e

# Clean old X lock (important on Render)
rm -f /tmp/.X1-lock

# Require password
if [ -z "$VNC_PASSWORD" ]; then
  echo "VNC_PASSWORD not set"
  exit 1
fi

x11vnc -storepasswd "$VNC_PASSWORD" /root/.vnc/passwd

# Start virtual display
Xvfb :1 -screen 0 1280x720x24 &
sleep 2

# Start openbox WITHOUT xdg-autostart
openbox --config-file /etc/xdg/openbox/rc.xml &
sleep 2

# Start browser
badwolf --no-sandbox https://www.instagram.com &
sleep 2

# Start VNC server (RAW TCP)
x11vnc \
  -display :1 \
  -rfbauth /root/.vnc/passwd \
  -forever \
  -shared \
  -rfbport 5901 \
  -noxdamage &
sleep 2

# Start noVNC bridge (CORRECT for Alpine)
websockify \
  --web=/usr/share/novnc/ \
  0.0.0.0:6080 \
  localhost:5901
EOF

RUN chmod +x /start.sh

EXPOSE 6080
CMD ["/start.sh"]
