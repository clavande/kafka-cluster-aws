from aws_cdk import (
    aws_iam as iam,
    Stack,
)
from constructs import Construct

class IamStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # Kafka Node Role
        self.kafka_role = iam.Role(
            self, "KafkaRole",
            assumed_by=iam.ServicePrincipal("ec2.amazonaws.com"),
            role_name="cl-cdk-kafka-role",
            description="Role for Kafka nodes with SSM and CloudWatch access"
        )
        self.kafka_role.add_managed_policy(
            iam.ManagedPolicy.from_aws_managed_policy_name("AmazonSSMManagedInstanceCore")
        )
        self.kafka_role.add_managed_policy(
            iam.ManagedPolicy.from_aws_managed_policy_name("CloudWatchAgentServerPolicy")
        )
        self.kafka_role.add_to_policy(
            iam.PolicyStatement(
                actions=[
                    "servicediscovery:RegisterInstance",
                    "servicediscovery:DeregisterInstance",
                    "servicediscovery:DiscoverInstances",
                    "ec2:DescribeInstances"
                ],
                resources=["*"]
            )
        )

        # Bastion Role
        self.bastion_role = iam.Role(
            self, "BastionRole",
            assumed_by=iam.ServicePrincipal("ec2.amazonaws.com"),
            role_name="cl-cdk-bastion-role",
            description="Role for Bastion host with SSM access"
        )
        self.bastion_role.add_managed_policy(
            iam.ManagedPolicy.from_aws_managed_policy_name("AmazonSSMManagedInstanceCore")
        )
