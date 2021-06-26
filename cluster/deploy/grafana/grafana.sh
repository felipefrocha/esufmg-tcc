helm repo add grafana https://grafana.github.io/helm-charts
helm repo update



helm upgrade grafana \
    grafana/grafana \
    -f values.yaml \
    --debug \
    --install