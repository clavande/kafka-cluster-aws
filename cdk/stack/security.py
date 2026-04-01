from aws_cdk import (
    aws_ec2 as ec2,
    Stack,
)
from constructs import Construct

class SecurityStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, vpc: ec2.IVpc, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        self.bastion_sg = ec2.SecurityGroup(
            self, "BastionSG",
            vpc=vpc,
            security_group_name="cl-cdk-bastion-sg",
            description="Allow SSH access to bastion host",
            allow_all_outbound=True
        )
        self.bastion_sg.add_ingress_rule(
            ec2.Peer.any_ipv4(), # Recommended to restrict this in production
            ec2.Port.tcp(22),
            "Allow SSH from anywhere"
        )

        self.kafka_sg = ec2.SecurityGroup(
            self, "KafkaSG",
            vpc=vpc,
            security_group_name="cl-cdk-kafka-sg",
            description="Allow Kafka communication within VPC",
            allow_all_outbound=True
        )
        self.kafka_sg.add_ingress_rule(
            ec2.Peer.ipv4(vpc.vpc_cidr_block),
            ec2.Port.tcp(9092),
            "Allow Kafka Client connections"
        )
        self.kafka_sg.add_ingress_rule(
            ec2.Peer.ipv4(vpc.vpc_cidr_block),
            ec2.Port.tcp(9093),
            "Allow Kafka Controller connections"
        )
        self.kafka_sg.add_ingress_rule(
            self.bastion_sg,
            ec2.Port.tcp(22),
            "Allow SSH from Bastion Host"
        )
