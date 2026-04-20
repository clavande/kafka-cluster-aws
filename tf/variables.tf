variable "aws_region" {
  description = "AWS Region where the Kafka cluster will be deployed"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix for all resources in this Terraform stack"
  type        = string
  default     = "cl-tf"
}

variable "aws_profile" {
  description = "AWS Profile to use for deployment"
  type        = string
  default     = "chinmay"
}

variable "vpc_cidr" {
  description = "CIDR block for the Terraform VPC"
  type        = string
  default     = "10.2.0.0/16"
}

variable "domain_name" {
  description = "Private Domain for Kafka nodes"
  type        = string
  default     = "cl-tf.local"
}

variable "instance_type" {
  description = "EC2 Instance type for Kafka Brokers"
  type        = string
  default     = "t3.medium"
}

variable "kafka_version" {
  description = "Version of Apache Kafka"
  type        = string
  default     = "3.5.1"
}

variable "scala_version" {
  description = "Version of Scala for Kafka distribution"
  type        = string
  default     = "2.13"
}

variable "kafka_cluster_id" {
  description = "Unique KRaft Cluster ID"
  type        = string
  default     = "xtXvUT8RTlCHw7d_k-21rA"
}

variable "kafka_secret_name" {
  description = "Name of the secret in Secrets Manager"
  type        = string
  default     = "cl-tf-kafka-admin-auth"
}
