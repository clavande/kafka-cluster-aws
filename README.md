# 🚀 Apache Kafka Cluster (Self-Managed Multi-IaC)

A production-grade, highly available Apache Kafka cluster (v3.5.1) deployed on AWS **without using MSK**. This project demonstrates an identical architecture implemented across three different Infrastructure-as-Code (IaC) providers.

---

## 🏗️ Architecture Detail
- **Kafka Mode**: KRaft (ZooKeeper-less) for modern, consolidated metadata management.
- **High Availability**: 3 Broker nodes distributed across **3 Availability Zones**.
- **Distribution**: 3 Private Subnets + 1 Public Subnet (with NAT Gateway for outbound traffic).
- **Security**: SSH-keyless management via **AWS SSM Session Manager** and least-privilege IAM roles.
- **Service Discovery**: Automated internal DNS using **Route 53 Private Hosted Zones**.

---

## 📂 Project Structure
| Directory | IaC Pillar | Language / Format | Network Range | Domain |
| :--- | :--- | :--- | :--- | :--- |
| `cdk/` | **AWS CDK** | Python | `10.0.0.0/16` | `cl-cdk.local` |
| `cfn/` | **CloudFormation** | YAML | `10.1.0.0/16` | `cl-cfn.local` |
| `tf/` | **Terraform** | HCL | `10.2.0.0/16` | `cl-tf.local` |

---

## 🚀 Deployment Instructions

### 1️⃣ CloudFormation (Native)
Run the automated deployment script from the root:
```powershell
powershell -ExecutionPolicy Bypass -File .\cfn\deploy.ps1
```

### 2️⃣ Terraform (Industry Standard)
Run the automated deployment script from the root:
```powershell
powershell -ExecutionPolicy Bypass -File .\tf\deploy.ps1
```

### 3️⃣ AWS CDK (Code-First)
Ensure you are in the `cdk/` directory:
```bash
cd cdk
cdk deploy --all --profile chinmay
```

---

## 🧪 Verification & Testing

### 1. Check Cluster Quorum
Log into **Broker 0** via SSM and run:
```bash
IP=$(hostname -I | awk '{print $1}')
/opt/kafka/bin/kafka-metadata-quorum.sh --bootstrap-server $IP:9092 describe --status
```
*Goal: `CurrentVoters: [0, 1, 2]` shows a healthy, synchronized quorum.*

### 2. Multi-Node Replication Test
Create a replicated topic across all 3 AZs:
```bash
/opt/kafka/bin/kafka-topics.sh --create --topic production-test \
  --bootstrap-server $IP:9092 --partitions 3 --replication-factor 3
```

Check replication status:
```bash
/opt/kafka/bin/kafka-topics.sh --describe --topic production-test --bootstrap-server $IP:9092
```

---

## 🛠️ Troubleshooting & Engineering
- **UserData Logs**: Check `/var/log/user-data.log` on any broker for detailed installation traces.
- **DNS Race Condition**: Fixed using the **"Placeholder + Sed"** pattern to ensure Route 53 propagation before service startup.
- **IP Dynamic Listeners**: Automated via `\$(hostname -I)` to support dynamic node identification.

---

## 🛡️ License & Credit
Implemented as part of a Senior-level Associate engineering exercise. 🚀🏆
