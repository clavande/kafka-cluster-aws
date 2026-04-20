# --- AMI FROM SSM (Same as CDK/CFN) ---
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}

# --- BASTION HOST ---
resource "aws_instance" "bastion" {
  ami                         = data.aws_ssm_parameter.al2023_ami.value
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_a.id
  iam_instance_profile        = aws_iam_instance_profile.broker.name
  vpc_security_group_ids      = [aws_security_group.kafka.id]
  associate_public_ip_address = true
  
  tags = {
    Name = "${var.project_name}-bastion"
  }
}

# --- KAFKA BROKERS ---
resource "aws_instance" "brokers" {
  count                  = 3
  ami                    = data.aws_ssm_parameter.al2023_ami.value
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private[count.index].id
  iam_instance_profile   = aws_iam_instance_profile.broker.name
  vpc_security_group_ids = [aws_security_group.kafka.id]

  # Ensure the instance is replaced when UserData changes
  user_data_replace_on_change = true

  # UserData with 'Placeholder' strategy (Matching CFN logic)
  user_data_base64 = base64encode(<<-EOF
    #!/bin/bash
    exec > /var/log/user-data.log 2>&1
    echo "Starting Secure Installation Node ${count.index}"
    yum update -y
    yum install -y java-17-amazon-corretto-devel wget tar jq

    KAFKA_DIR="/opt/kafka"
    mkdir -p $KAFKA_DIR
    curl -L "https://archive.apache.org/dist/kafka/${var.kafka_version}/kafka_${var.scala_version}-${var.kafka_version}.tgz" -o /tmp/kafka.tgz
    tar -xzf /tmp/kafka.tgz -C $KAFKA_DIR --strip-components=1

    # --- SECRETS MANAGER INTEGRATION ---
    echo "Fetching credentials from Secrets Manager..."
    REGION="${var.aws_region}"
    SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id ${var.kafka_secret_name} --region $REGION --query SecretString --output text)
    KAFKA_USER=$(echo $SECRET_JSON | jq -r .username)
    KAFKA_PASS=$(echo $SECRET_JSON | jq -r .password)

    # 1. Create JAAS config for SASL/SCRAM (For Client Entrance on 9092)
    cat <<INNER_EOF > $KAFKA_DIR/config/kafka_server_jaas.conf
    KafkaServer {
        org.apache.kafka.common.security.scram.ScramLoginModule required
        username="$KAFKA_USER"
        password="$KAFKA_PASS";
    };
    INNER_EOF

    # 2. Update server.properties (9092=CLIENT, 9093=QUORUM, 9094=ADMIN/INTERNAL)
    cat <<'INNER_EOF' > $KAFKA_DIR/config/kraft/server.properties
    process.roles=broker,controller
    node.id=${count.index}
    controller.quorum.voters=0@broker-0.${var.domain_name}:9093,1@broker-1.${var.domain_name}:9093,2@broker-2.${var.domain_name}:9093
    
    # 3-Port Segregation
    listeners=SASL_PLAINTEXT://REPLACE_IP:9092,CONTROLLER://REPLACE_IP:9093,INTERNAL://REPLACE_IP:9094
    inter.broker.listener.name=INTERNAL
    controller.listener.names=CONTROLLER
    advertised.listeners=SASL_PLAINTEXT://broker-${count.index}.${var.domain_name}:9092,INTERNAL://broker-${count.index}.${var.domain_name}:9094
    
    # Protocol Mapping
    listener.security.protocol.map=CONTROLLER:PLAINTEXT,SASL_PLAINTEXT:SASL_PLAINTEXT,INTERNAL:PLAINTEXT
    
    # SASL Configuration
    sasl.enabled.mechanisms=SCRAM-SHA-512
    
    log.dirs=/var/lib/kafka-logs
    num.partitions=3
    offsets.topic.replication.factor=3
    transaction.state.log.replication.factor=3
    transaction.state.log.min.isr=2
    INNER_EOF

    # IP Replacement
    IP_ADDR=$(hostname -I | awk '{print $1}')
    sed -i "s/REPLACE_IP/$IP_ADDR/g" $KAFKA_DIR/config/kraft/server.properties

    # 3. Format & Configure
    $KAFKA_DIR/bin/kafka-storage.sh format -t ${var.kafka_cluster_id} -c $KAFKA_DIR/config/kraft/server.properties
    
    mkdir -p /var/lib/kafka-logs
    chown -R ec2-user:ec2-user /var/lib/kafka-logs
    chown -R ec2-user:ec2-user /opt/kafka

    # 4. Service Environment
    cat <<INNER_EOF > /etc/systemd/system/kafka.service
    [Unit]
    Description=Apache Kafka Cluster Service
    [Service]
    User=ec2-user
    Environment="KAFKA_OPTS=-Djava.security.auth.login.config=$KAFKA_DIR/config/kafka_server_jaas.conf"
    ExecStart=$KAFKA_DIR/bin/kafka-server-start.sh $KAFKA_DIR/config/kraft/server.properties
    Restart=always
    RestartSec=15
    [Install]
    WantedBy=multi-user.target
    INNER_EOF

    systemctl enable kafka
    systemctl start kafka

    # 5. Register the SCRAM user via Internal Admin Port 9094
    echo "Registering admin user in Kafka Metadata via $IP_ADDR:9094..."
    MAX_RETRIES=20
    COUNT=0
    until $KAFKA_DIR/bin/kafka-configs.sh --bootstrap-server $IP_ADDR:9094 --alter --add-config "SCRAM-SHA-512=[password=$KAFKA_PASS]" --entity-type users --entity-name $KAFKA_USER || [ $COUNT -eq $MAX_RETRIES ]; do
      echo "Waiting for Quorum on $IP_ADDR:9094..."
      sleep 20
      COUNT=$((COUNT + 1))
    done
  EOF
  )

  tags = {
    Name = "${var.project_name}-broker-${count.index}"
  }
}

# --- DNS A-RECORDS (3 Nodes) ---
resource "aws_route53_record" "brokers" {
  count   = 3
  zone_id = aws_route53_zone.kafka.zone_id
  name    = "broker-${count.index}.${var.domain_name}"
  type    = "A"
  ttl     = 60
  records = [aws_instance.brokers[count.index].private_ip]
}

# --- OUTPUTS ---
output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "broker_private_ips" {
  value = aws_instance.brokers[*].private_ip
}
