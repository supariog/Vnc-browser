FROM alpine:3.19

ENV DISPLAY=:0
ENV VNC_PORT=5900
ENV NOVNC_PORT=6080

# Enable community repository
RUN sed -i 's/#http/http/g' /etc/apk/repositories && \
    apk update

# Install required packages
RUN apk add --no-cache \
    xvfb \
    x11vnc \
    openbox \
    badwolf \
    novnc \
    websockify \
    dbus \
    ttf-dejavu \
    bash

# Create VNC password from ENV
RUN mkdir -p /root/.vnc

# Startup script
RUN cat << 'EOF' > /start.sh
#!/bin/sh

# Set VNC password
if [ -n "$VNC_PASSWORD" ]; then
  x11vnc -storepasswd "$VNC_PASSWORD" /root/.vnc/passwd
fi

# Start virtual display
Xvfb :0 -screen 0 1280x720x24 &

# Start Openbox session
openbox-session &

# Start browser
badwolf https://www.instagram.com &

# Start VNC server
x11vnc -display :0 \
  -rfbauth /root/.vnc/passwd \
  -forever -shared -nopw &

# Start noVNC
websockify --web=/usr/share/novnc/ $NOVNC_PORT localhost:$VNC_PORT
EOF

RUN chmod +x /start.sh

EXPOSE 6080

CMD ["/start.sh"]
