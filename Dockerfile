FROM alpine:3.19

ENV DISPLAY=:0
ENV NOVNC_PORT=6080
ENV VNC_PASSWORD=alpine

# 1. Install packages
# Added: mesa-dri-gallium (REQUIRED for WebKit rendering), xsetroot (for background color)
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
    ttf-dejavu \
    adwaita-icon-theme \
    mesa-dri-gallium \
    xsetroot \
    ca-certificates

# 2. Create user
RUN adduser -D user

# 3. User Configuration
USER user
WORKDIR /home/user

# Configure Openbox to auto-start Badwolf
RUN mkdir -p ~/.config/openbox && \
    echo "badwolf &" > ~/.config/openbox/autostart

# Configure Xstartup
RUN mkdir -p ~/.vnc && \
    cat << 'EOF' > ~/.vnc/xstartup
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

# Set a background color (Dark Grey) so we know X is working
xsetroot -solid "#333333"

# Start Window Manager
exec dbus-launch --exit-with-session openbox-session &
EOF
RUN chmod +x ~/.vnc/xstartup

# 4. Entrypoint
USER root
RUN cat << 'EOF' > /entrypoint.sh
#!/bin/sh
set -e

echo "Starting Xvfb..."
Xvfb :0 -screen 0 1280x720x24 &
sleep 2

echo "Configuring VNC..."
mkdir -p /home/user/.vnc
x11vnc -storepasswd "$VNC_PASSWORD" /home/user/.vnc/passwd
chown -R user:user /home/user/.vnc
chmod 600 /home/user/.vnc/passwd

echo "Starting Session..."
su user -c "DISPLAY=:0 ~/.vnc/xstartup" &

echo "Starting x11vnc..."
x11vnc -display :0 \
  -rfbauth /home/user/.vnc/passwd \
  -forever \
  -shared \
  -bg

echo "Starting noVNC..."
websockify --web=/usr/share/novnc/ 0.0.0.0:6080 localhost:5900
EOF
RUN chmod +x /entrypoint.sh

EXPOSE 6080
CMD ["/entrypoint.sh"]
