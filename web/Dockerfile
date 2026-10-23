FROM node:20.14.0-alpine3.20

WORKDIR /app

RUN apk upgrade --no-cache

COPY package*.json ./

RUN npm install --omit=dev

COPY . .

# Remove build tools, npm and yarn to eliminate bundled dev vulnerabilities
RUN rm -rf /usr/local/lib/node_modules/npm \
           /usr/local/bin/npm \
           /usr/local/bin/npx \
           /opt/yarn* \
           /usr/local/bin/yarn* \
           /usr/local/bin/yarnpkg \
           /usr/local/bin/corepack

# Ensure uploads directory exists and set ownership to unprivileged user node
RUN mkdir -p /app/public/uploads && chown -R node:node /app

USER node

EXPOSE 3000

HEALTHCHECK --interval=5s --timeout=5s --retries=5 --start-period=5s \
  CMD wget -qO- http://127.0.0.1:3000/health > /dev/null || exit 1

CMD ["node", "src/server.js"]
