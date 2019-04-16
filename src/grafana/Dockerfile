FROM grafana/grafana:latest
COPY prometheus.yml /etc/grafana/provisioning/datasources
COPY default.yml /etc/grafana/provisioning/dashboards
COPY dashboards/ /var/dashboards
