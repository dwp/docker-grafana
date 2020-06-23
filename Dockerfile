FROM grafana/grafana:7.0.3

# Expose grafana port
EXPOSE 3000


COPY entrypoint.sh /bin/entrypoint.sh
USER root
RUN chmod 0755 /bin/entrypoint.sh

USER grafana
ENTRYPOINT [ "/bin/entrypoint.sh" ]
