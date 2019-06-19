#
# Chromedriver Dockerfile
#
FROM debian:stretch-slim

# Install the base requirements to run and debug webdriver implementations:
RUN export DEBIAN_FRONTEND=noninteractive \
  && apt-get update \
  && apt-get dist-upgrade -y \
  && apt-get install --no-install-recommends --no-install-suggests -y \
  xvfb \
  xauth \
  ca-certificates \
  x11vnc \
  fluxbox \
  xvt \
  curl \
  # Remove obsolete files:
  && apt-get clean \
  && rm -rf \
  /tmp/* \
  /usr/share/doc/* \
  /var/cache/* \
  /var/lib/apt/lists/* \
  /var/tmp/*

# Patch xvfb-run to support TCP port listening (disabled by default):
RUN sed -i 's/LISTENTCP=""/LISTENTCP="-listen tcp"/' /usr/bin/xvfb-run

# Avoid permission issues with host mounts by assigning a user/group with
# uid/gid 1000 (usually the ID of the first user account on GNU/Linux):
RUN useradd -u 1000 -m -U webdriver

WORKDIR /home/webdriver

# Install the latest versions of Google Chrome and Chromedriver:
RUN export DEBIAN_FRONTEND=noninteractive \
  && apt-get update \
  && apt-get install \
  unzip \
  && \
  DL=https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
  && curl -sL "$DL" > /tmp/chrome.deb \
  && apt install --no-install-recommends --no-install-suggests -y \
  /tmp/chrome.deb \
  && CHROMIUM_FLAGS='--no-sandbox --disable-dev-shm-usage' \
  # Patch Chrome launch script and append CHROMIUM_FLAGS to the last line:
  && sed -i '${s/$/'" $CHROMIUM_FLAGS"'/}' /opt/google/chrome/google-chrome \
  && BASE_URL=https://chromedriver.storage.googleapis.com \
  && VERSION=$(curl -sL "$BASE_URL/LATEST_RELEASE") \
  && curl -sL "$BASE_URL/$VERSION/chromedriver_linux64.zip" -o /tmp/driver.zip \
  && unzip /tmp/driver.zip \
  && mv chromedriver /usr/local/bin/ \
  && chmod +x /usr/local/bin/chromedriver \
  # Remove obsolete files:
  && apt-get autoremove --purge -y \
  unzip \
  && apt-get clean \
  && rm -rf \
  /tmp/* \
  /usr/share/doc/* \
  /var/cache/* \
  /var/lib/apt/lists/* \
  /var/tmp/*

COPY entrypoint.sh /usr/local/bin/entrypoint
COPY vnc-start.sh /usr/local/bin/vnc-start

USER webdriver

# Configure Xvfb via environment variables:
ENV SCREEN_WIDTH 1440
ENV SCREEN_HEIGHT 900
ENV SCREEN_DEPTH 24
ENV DISPLAY :0

EXPOSE 4444
EXPOSE 9515
EXPOSE 6000
EXPOSE 5900

ENTRYPOINT ["entrypoint", "chromedriver"]
CMD ["--port=9515", "--whitelisted-ips"]

