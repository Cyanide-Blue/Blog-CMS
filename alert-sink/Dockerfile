FROM python:3.11-alpine

WORKDIR /app

RUN apk upgrade --no-cache && \
    addgroup -g 10001 -S appgroup && \
    adduser -u 10001 -S appuser -G appgroup

COPY server.py .

# Remove pip, setuptools, wheel to eliminate unused packages with CVEs
RUN rm -rf /usr/local/lib/python3.11/site-packages/pip* \
           /usr/local/lib/python3.11/site-packages/setuptools* \
           /usr/local/lib/python3.11/site-packages/wheel* \
           /usr/local/lib/python3.11/site-packages/jaraco* \
           /usr/local/bin/pip*

RUN mkdir -p /logs && chown -R appuser:appgroup /logs /app

USER appuser

EXPOSE 9099

HEALTHCHECK --interval=5s --timeout=5s --retries=5 --start-period=5s \
  CMD python3 -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:9099/health')" > /dev/null || exit 1

CMD ["python3", "-u", "server.py"]
