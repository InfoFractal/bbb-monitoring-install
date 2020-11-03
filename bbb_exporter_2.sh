#!/bin/bash
conf=/etc/bigbluebutton-exporter/settings.env
apt install -y python3-pip
cd /opt
git clone https://github.com/greenstatic/bigbluebutton-exporter.git
cd bigbluebutton-exporter/
git checkout release-0.6
pip3 install -r requirements.txt
useradd -r -d /opt/bigbluebutton-exporter -s /usr/sbin/nologin bbb-exporter
chown -R bbb-exporter:bbb-exporter /opt/bigbluebutton-exporter
cp /opt/bigbluebutton-exporter/extras/systemd/bigbluebutton-exporter.service /lib/systemd/system/
mkdir /etc/bigbluebutton-exporter
cp /opt/bigbluebutton-exporter/extras/systemd/bigbluebutton-exporter/* /etc/bigbluebutton-exporter

echo "API_BASE_URL=$(bbb-conf --secret | grep URL\: | cut -f 6 -d " ")api/" > $conf
echo "API_SECRET=$(bbb-conf --secret | grep Secret\: | cut -f 6 -d " ")" >> $conf
echo "BIND_IP=127.0.0.1" >> $conf
echo "PORT=9688" >> $conf
echo "RECORDINGS_METRICS_READ_FROM_DISK=true" >> $conf

systemctl start bigbluebutton-exporter
systemctl enable bigbluebutton-exporter

echo 'metrics:$apr1$VNUloPG8$3hHu1ipHMM/6gYhn8c15S.' > /etc/nginx/.htpasswd
sudo tee /etc/bigbluebutton/nginx/monitoring.nginx <<"EOF"
# BigBlueButton Exporter (metrics)
location /metrics/ {
    auth_basic "BigBlueButton Exporter";
    auth_basic_user_file /etc/nginx/.htpasswd;
    proxy_pass http://127.0.0.1:9688/;
    include proxy_params;
}
location /node_exporter/metrics {
    auth_basic "BigBlueButton Exporter";
    auth_basic_user_file /etc/nginx/.htpasswd;
    proxy_pass http://127.0.0.1:9100/node_exporter/metrics;
    include proxy_params;
}
EOF
echo $(nginx -t)
systemctl reload nginx
