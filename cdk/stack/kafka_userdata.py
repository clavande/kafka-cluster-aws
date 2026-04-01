def get_kafka_userdata(node_id, brokers, hostname):
    # Prepare controller list
    voters = ",".join([f"{i}@{host}:9093" for i, host in enumerate(brokers)])
    CLUSTER_ID = "xtXvUT8RTlCHw7d_k-21rA"
    
    return f"""#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "Starting Kafka installation..."

# 1. Install Dependencies
yum update -y
yum install -y java-17-amazon-corretto-devel wget tar

# 2. Download and Unpack Kafka
KAFKA_VERSION="3.5.1"
SCALA_VERSION="2.13"
KAFKA_DIR="/opt/kafka"
KAFKA_URL="https://archive.apache.org/dist/kafka/$KAFKA_VERSION/kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz"

mkdir -p $KAFKA_DIR
wget -q $KAFKA_URL -O /tmp/kafka.tgz
tar -xzf /tmp/kafka.tgz -C $KAFKA_DIR --strip-components=1

# 3. Get Networking Info
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
ADDR=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)
echo "Instance IP: $ADDR"

# 4. Create Configuration
mkdir -p /var/lib/kafka-logs
chown -R ec2-user:ec2-user /var/lib/kafka-logs
chown -R ec2-user:ec2-user $KAFKA_DIR

cat <<EOF > $KAFKA_DIR/config/kraft/server.properties
process.roles=broker,controller
node.id={node_id}
controller.quorum.voters={voters}
listeners=PLAINTEXT://$ADDR:9092,CONTROLLER://$ADDR:9093
inter.broker.listener.name=PLAINTEXT
advertised.listeners=PLAINTEXT://{hostname}:9092
controller.listener.names=CONTROLLER
listener.security.protocol.map=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT
log.dirs=/var/lib/kafka-logs
num.partitions=3
offsets.topic.replication.factor=3
transaction.state.log.replication.factor=3
transaction.state.log.min.isr=2
EOF

# 5. Format Storage
echo "Formatting storage with Cluster ID {CLUSTER_ID}..."
$KAFKA_DIR/bin/kafka-storage.sh format -t {CLUSTER_ID} -c $KAFKA_DIR/config/kraft/server.properties

# 6. Service Definition
cat <<EOF > /etc/systemd/system/kafka.service
[Unit]
Description=Apache Kafka Cluster Service
After=network.target

[Service]
Type=simple
User=ec2-user
Environment="KAFKA_HEAP_OPTS=-Xmx1G -Xms1G"
ExecStart=$KAFKA_DIR/bin/kafka-server-start.sh $KAFKA_DIR/config/kraft/server.properties
ExecStop=$KAFKA_DIR/bin/kafka-server-stop.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 7. Start Kafka
systemctl daemon-reload
systemctl enable kafka
systemctl start kafka

# 8. CloudWatch Agent
yum install -y amazon-cloudwatch-agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c default -s
echo "Kafka installation complete!"
"""
