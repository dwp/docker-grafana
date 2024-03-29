FROM grafana/grafana:7.4.0

# Expose grafana port
EXPOSE 3000

USER root

RUN apk upgrade --update-cache --available && \
    apk add --no-cache aws-cli jq && \
    chown -R grafana /etc/grafana

COPY entrypoint.sh /bin/entrypoint.sh
RUN chmod 0755 /bin/entrypoint.sh

USER grafana
ENTRYPOINT [ "/bin/entrypoint.sh" ]
