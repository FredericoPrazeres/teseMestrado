# Dar setup ao Prometheus/Grafana

    Correr o compose do prometheus/grafana
    
    Adicionar uma nova data source com o seguinte URL: http://prometheus:9090

    Verificar ligação: docker exec -it grafana ping prometheus

    Importar a dashboard do jenkins com o id 9964