from aws_cdk import (
    aws_ec2 as ec2,
    aws_iam as iam,
    aws_route53 as route53,
    Stack,
    CfnOutput,
    Tags,
)
import hashlib
from constructs import Construct
from .kafka_userdata import get_kafka_userdata

class ComputeStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, vpc: ec2.IVpc, kafka_sg: ec2.ISecurityGroup, bastion_sg: ec2.ISecurityGroup, kafka_role: iam.IRole, bastion_role: iam.IRole, zone: route53.IPrivateHostedZone, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # Bastion Host
        self.bastion = ec2.Instance(
            self, "BastionHost",
            instance_name="cl-cdk-bastion",
            instance_type=ec2.InstanceType.of(ec2.InstanceClass.T3, ec2.InstanceSize.MICRO),
            machine_image=ec2.MachineImage.latest_amazon_linux2023(),
            vpc=vpc,
            vpc_subnets=ec2.SubnetSelection(subnet_type=ec2.SubnetType.PUBLIC),
            security_group=bastion_sg,
            role=bastion_role,
            propagate_tags_to_volume_on_creation=True
        )

        private_subnets = vpc.select_subnets(subnet_type=ec2.SubnetType.PRIVATE_WITH_EGRESS).subnets
        num_brokers = min(len(private_subnets), 3)
        hostnames = [f"broker-{i}.cl-kafka.local" for i in range(num_brokers)]
        
        for i in range(num_brokers):
            # UserData with Route53 Hostnames
            userdata_script = get_kafka_userdata(
                node_id=i, 
                brokers=hostnames, 
                hostname=hostnames[i]
            )
            
            # Create a hash for forcing logical ID replacement
            script_hash = hashlib.md5(userdata_script.encode('utf-8')).hexdigest()[:8]

            # Block Device
            block_device = ec2.BlockDevice(
                device_name="/dev/sdf",
                volume=ec2.BlockDeviceVolume.ebs(
                    volume_size=20,
                    volume_type=ec2.EbsDeviceVolumeType.GP3,
                    encrypted=True,
                    delete_on_termination=True
                )
            )

            # Instance setup (Using dynamic Logical ID to force replacement)
            instance = ec2.Instance(
                self, f"KafkaBroker{i}-{script_hash}",
                instance_name=f"cl-cdk-kafka-broker-{i}",
                instance_type=ec2.InstanceType.of(ec2.InstanceClass.T3, ec2.InstanceSize.MEDIUM),
                machine_image=ec2.MachineImage.latest_amazon_linux2023(),
                vpc=vpc,
                vpc_subnets=ec2.SubnetSelection(subnets=[private_subnets[i]]),
                security_group=kafka_sg,
                role=kafka_role,
                block_devices=[block_device],
                propagate_tags_to_volume_on_creation=True
            )
            instance.add_user_data(userdata_script)
            Tags.of(instance).add("UserDataVersion", script_hash)

            # Register A Record in Route 53
            route53.ARecord(
                self, f"KafkaRecord{i}-{script_hash}",
                zone=zone,
                target=route53.RecordTarget.from_ip_addresses(instance.instance_private_ip),
                record_name=f"broker-{i}",
                delete_existing=True
            )

        # Success Outputs
        CfnOutput(self, "BastionPublicIP", value=self.bastion.instance_public_ip)
        for i, host in enumerate(hostnames):
            CfnOutput(self, f"Broker{i}Hostname", value=host)
