FROM grafana/grafana:7.0.3

# Expose grafana port
EXPOSE 3000

USER root

RUN sed -i -e 's/v[[:digit:]]\..*\//edge\//g' /etc/apk/repositories && \
    apk upgrade --update-cache --available && \
    apk add --no-cache aws-cli

COPY entrypoint.sh /bin/entrypoint.sh
RUN chmod 0755 /bin/entrypoint.sh

USER grafana
ENTRYPOINT [ "/bin/entrypoint.sh" ]
