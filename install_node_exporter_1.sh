#!/bin/bash
#run as root to install node exporter on /usr/local and to listen on 127.0.0.1:9100/node_exporter/metrics
#use an http proxy to proxy pass <url>/node_exporter/metrics to 127.0.0.1:9100/node_exporter/metrics
sudo useradd --no-create-home --shell /bin/false node_exporter
curl -fsSL https://github.com/prometheus/node_exporter/releases/download/v0.17.0/node_exporter-0.17.0.linux-amd64.tar.gz \
  | sudo tar -zxvf - -C /usr/local/bin --strip-components=1 node_exporter-0.17.0.linux-amd64/node_exporter \
  && sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

sudo tee /etc/systemd/system/node_exporter.service <<"EOF"
[Unit]
Description=Node Exporter

[Service]
User=node_exporter
Group=node_exporter
EnvironmentFile=-/etc/node_exporter
ExecStart=/usr/local/bin/node_exporter $OPTIONS

[Install]
WantedBy=multi-user.target
EOF

echo 'OPTIONS="--web.telemetry-path="/node_exporter/metrics/"' > /etc/node_exporter

sudo systemctl daemon-reload && \
sudo systemctl start node_exporter && \
sudo systemctl status node_exporter && \
sudo systemctl enable node_exporter
