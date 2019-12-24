# Build: docker build --build-arg VERSION="1.0.0" -t docker_puppeteer:1.0.0 .
# Run: docker run --shm-size 1G --rm -v <path_to_script>:/app/index.js -v <path_to_screenshot_dir>:/tmp/screenshots -v <path_to_urls_file>:/tmp/urls.csv docker_puppeteer:1.0.0
# Example: docker run --shm-size 1G --rm -v $(pwd)/examples/hydrobuilder-warm.js:/app/index.js -v $(pwd)/screenshots:/tmp/screenshots -v $(pwd)/files/urls.csv:/tmp/urls.csv docker_puppeteer:1.0.0
FROM node:8-slim

ARG VERSION="1.0.0"
ARG MAINTAINER="Hydrobuilder.com \"trevor@hydrobuilder.com\""

ENV VERSION $VERSION
ENV MAINTAINER $MAINTAINER

MAINTAINER $MAINTAINER

COPY files/dumb-init_1.2.1_amd64.deb /root/dumb-init_1.2.1_amd64.deb

RUN apt-get update && \
apt-get install -yq gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 \
libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 \
libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 \
libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 \
fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst ttf-freefont \
ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils wget && \
dpkg -i /root/dumb-init_*.deb && rm -f /root/dumb-init_*.deb && \
apt-get clean && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

RUN yarn global add puppeteer@1.8.0 && yarn cache clean

ENV NODE_PATH="/usr/local/share/.config/yarn/global/node_modules:${NODE_PATH}"

ENV PATH="/tools:${PATH}"

RUN groupadd -r pptruser && useradd -r -g pptruser -G audio,video pptruser

COPY --chown=pptruser:pptruser ./tools /tools

# Set language to UTF8
ENV LANG="C.UTF-8"

WORKDIR /app

# Add user so we don't need --no-sandbox.
RUN mkdir /screenshots \
	&& mkdir -p /home/pptruser/Downloads \
    && chown -R pptruser:pptruser /home/pptruser \
    && chown -R pptruser:pptruser /usr/local/share/.config/yarn/global/node_modules \
    && chown -R pptruser:pptruser /screenshots \
    && chown -R pptruser:pptruser /app \
    && chown -R pptruser:pptruser /tools

# Run everything after as non-privileged user.
USER pptruser

# --cap-add=SYS_ADMIN
# https://docs.docker.com/engine/reference/run/#additional-groups

ENTRYPOINT ["dumb-init", "--"]

# CMD ["/usr/local/share/.config/yarn/global/node_modules/puppeteer/.local-chromium/linux-526987/chrome-linux/chrome"]

CMD ["node", "index.js"]
