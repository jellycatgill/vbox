#!/bin/bash


# basic setup
SYSMON_DIR=/opt/sysmon
mkdir -p $SYSMON_DIR
mkdir -p $SYSMON_DIR/logs
apt-get install wget curl jq -y


# Graphite port 3001
echo
echo "Installing Graphite on port 3001..."
cd $SYSMON_DIR
curl -fsSL https://get.docker.com -o get-docker.sh
sh ./get-docker.sh
docker run -d --name graphite --restart=always -p 3001:80 -p 2003-2004:2003-2004 -p 2023-2024:2023-2024 -p 8125:8125/udp -p 8126:8126 graphiteapp/graphite-statsd


# Graphite exporter port 9108
echo
echo "Installing Graphite exporter on port 9108..."
cd $SYSMON_DIR
wget https://github.com/prometheus/graphite_exporter/releases/download/v0.5.0/graphite_exporter-0.5.0.linux-amd64.tar.gz
tar xfz graphite_exporter-0.5.0.linux-amd64.tar.gz
cd $SYSMON_DIR/graphite_exporter-0.5.0.linux-amd64
nohup ./graphite_exporter >> $SYSMON_DIR/logs/graphite_exporter.log &

# Node exporter port 9100
echo
echo "Installing Node exporter on port 9100..."
cd $SYSMON_DIR
wget https://github.com/prometheus/node_exporter/releases/download/v0.17.0/node_exporter-0.17.0.linux-amd64.tar.gz
tar xfz node_exporter-0.17.0.linux-amd64.tar.gz
cd $SYSMON_DIR/node_exporter-0.17.0.linux-amd64
nohup ./node_exporter >> $SYSMON_DIR/logs/node_exporter.log &

# Prometheus port 9090
echo
echo "Installing Prometheus on port 9090..."
cd $SYSMON_DIR
wget https://github.com/prometheus/prometheus/releases/download/v2.8.0-rc.0/prometheus-2.8.0-rc.0.linux-amd64.tar.gz
tar xfz prometheus-2.8.0-rc.0.linux-amd64.tar.gz
echo "
  - job_name: 'graphite_exporter'
    static_configs:
    - targets: ['localhost:9108']

  - job_name: 'node_exporter'
    static_configs:
    - targets: ['localhost:9100'] " >>  $SYSMON_DIR/prometheus-2.8.0-rc.0.linux-amd64/prometheus.yml
cd $SYSMON_DIR/prometheus-2.8.0-rc.0.linux-amd64
nohup ./prometheus >> $SYSMON_DIR/logs/prometheus.log &

# Grafana port 3000
echo
echo "Installing Graphana on port 3000..."
cd $SYSMON_DIR
wget https://dl.grafana.com/oss/release/grafana_6.0.1_amd64.deb
dpkg -i grafana_6.0.1_amd64.deb
apt-get install -f -y
systemctl start grafana-server
systemctl enable grafana-server
sleep 30


# API Key
APIKEY=`curl -X POST -H "Content-Type: application/json" -d '{"name":"apikeycurl", "role": "Admin"}' http://admin:admin@localhost:3000/api/auth/keys 2>/dev/null | jq -r '.[]' 2>/dev/null  | tail -1`
echo "APIKEY = $APIKEY"


# Data Source
echo "Creating default datasource..."
curl -X POST --insecure -H "Authorization: Bearer $APIKEY" -H "Content-Type: application/json" -d '{
  "name":"ds01",
  "type":"prometheus",
  "url":"http://localhost:9090",
  "access":"proxy",
  "basicAuth":false,
  "isDefault":true
}' http://localhost:3000/api/datasources

echo "List of datasources"
curl -X GET --insecure -H "Authorization: Bearer $APIKEY" -H "Content-Type: application/json" http://localhost:3000/api/datasources | jq -r '.[]'


# Dash Board
echo "Creating dashboard..."
curl -i -H "Authorization: Bearer $APIKEY" -H "Content-Type: application/json" -d @/opt/vbox/dashboard.json http://localhost:3000/api/dashboards/db

#echo "List of dashboards"
#curl -X GET --insecure -H "Authorization: Bearer $APIKEY" -H "Content-Type: application/json" http://localhost:3000/api/dashboards


