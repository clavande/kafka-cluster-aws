# Apache Kafka Cluster on AWS (Self-Managed)

A production-grade, self-managed Apache Kafka cluster implementation on AWS using Infrastructure as Code (IaC). This repository follows a multi-IaC structure, starting with an AWS CDK (Python) implementation.

## 🏗️ Architecture

```text
[ Internet ]
      |
      v
[ Public Subnets ]
      |-- NAT Gateway (1)
      |-- Bastion Host (SSM Managed)
      v
[ Private Subnets (3 AZs) ]
      |-- Broker 0 (KRaft Controller+Broker) -- [ gp3 EBS (20G) ]
      |-- Broker 1 (KRaft Controller+Broker) -- [ gp3 EBS (20G) ]
      |-- Broker 2 (KRaft Controller+Broker) -- [ gp3 EBS (20G) ]
```

### Key Components

- **Networking**: VPC (10.0.0.0/16) with 3 AZs. Public subnets for incoming NAT traffic and a bastion host; private subnets for Kafka brokers.
- **Compute**: 3 x `t3.medium` instances (1 per AZ) for Kafka brokers. 1 x `t3.micro` instance for a bastion host.
- **Storage**: Amazon EBS (gp3) for Kafka logs, ensuring high IOPS and reliability over ephemeral storage.
- **KRaft Mode**: Using Apache Kafka 3.x's KRaft (Kafka Raft) mode to eliminate dependency on Apache Zookeeper, simplifying the architecture and improving metadata management.

---

## 🛠️ Design Decisions

### KRaft vs. ZooKeeper
- **KRaft** is the modern way to manage Kafka metadata without Zookeeper. It reduces operational overhead, improves scaling limits, and avoids the "split-brain" issues common with Zookeeper clusters in separate failure domains.

### EC2 vs. Amazon MSK
- This project implements **Self-Managed Kafka on EC2** to provide full control over configuration and deeper understanding of Kafka's internals. MSK is safer for production but less customizable for high-performance tuning or non-standard protocols.

### EBS vs. EFS
- Kafka is designed for direct-attached storage (DAS) or low-latency block storage like **Amazon EBS**. Using Amazon EFS (Network File System) would introduce latency overhead and performance bottlenecks for high-throughput messaging.

### SSM vs. SSH
- Access to instances is handled via **AWS Systems Manager (SSM) Session Manager**. This eliminates the need to manage SSH keys or open port 22 to the public internet, significantly hardening the security posture.

---

## 🚀 Deployment (CDK)

### Prerequisites
- AWS CLI configured with appropriate permissions.
- Python 3.9+ installed.
- Node.js (for AWS CDK CLI).

### Steps
1. Navigate to the `cdk` directory:
   ```bash
   cd cdk
   ```
2. Set up the virtual environment and install dependencies:
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .\.venv\Scripts\activate
   pip install -r requirements.txt
   ```
3. Bootstrap then deploy the CDK stacks:
   ```bash
   cdk bootstrap
   cdk deploy --all
   ```

---

## 🧪 Testing the Cluster

1. **Connect to a Broker via SSM**:
   Use the AWS Console or AWS CLI to start a session with a broker:
   ```bash
   aws ssm start-session --target <BROKER_INSTANCE_ID>
   ```
2. **Create a Topic**:
   ```bash
   /opt/kafka/bin/kafka-topics.sh --create --topic test-topic --bootstrap-server localhost:9092 --partitions 3 --replication-factor 3
   ```
3. **Produce Messages**:
   ```bash
   /opt/kafka/bin/kafka-console-producer.sh --topic test-topic --bootstrap-server localhost:9092
   > Hello Kafka!
   > Testing KRaft...
   ```
4. **Consume Messages from another Broker**:
   ```bash
   /opt/kafka/bin/kafka-console-consumer.sh --topic test-topic --bootstrap-server localhost:9092 --from-beginning
   ```

---

## ⚠️ Important Note on Naming
- All resources are prefixed with **`cl-cdk-`** to avoid conflicts in shared environments.
- Future implementations will use `cl-cfn-` and `cl-tf-`.
