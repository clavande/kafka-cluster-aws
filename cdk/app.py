import aws_cdk as cdk
from stack import VpcStack, SecurityStack, IamStack, ComputeStack

app = cdk.App()

# 1. VPC Stack
vpc_stack = VpcStack(
    app, "ClCdkVpcStack",
    stack_name="cl-cdk-vpc-stack"
)

# 2. IAM Stack
iam_stack = IamStack(
    app, "ClCdkIamStack",
    stack_name="cl-cdk-iam-stack"
)

# 3. Security Stack
security_stack = SecurityStack(
    app, "ClCdkSecurityStack",
    vpc=vpc_stack.vpc,
    stack_name="cl-cdk-security-stack"
)

# 4. Compute Stack
compute_stack = ComputeStack(
    app, "ClCdkComputeStack",
    vpc=vpc_stack.vpc,
    kafka_sg=security_stack.kafka_sg,
    bastion_sg=security_stack.bastion_sg,
    kafka_role=iam_stack.kafka_role,
    bastion_role=iam_stack.bastion_role,
    zone=vpc_stack.zone,
    stack_name="cl-cdk-compute-stack"
)

app.synth()
