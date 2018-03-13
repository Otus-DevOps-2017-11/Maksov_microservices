FROM grafana/grafana:5.0.0

ENV GF_SECURITY_ADMIN_USER admin
ENV GF_SECURITY_ADMIN_PASSWORD 0ldS3cret
ENV GF_DS_PROMETHEUS_SERVER Prometheus Server
ENV DS_PROMETHEUS_SERVER Prometheus Server

COPY provisioning/dashboards/dashboards.yaml /etc/grafana/provisioning/dashboards/dashboards.yaml

COPY provisioning/datasources/datasource.yaml /etc/grafana/provisioning/datasources/datasources.yaml

COPY dashboards/*.json /var/lib/grafana/dashboards/