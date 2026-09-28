module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = var.azs
}

module "security_group" {
  source = "./modules/security_group"

  project_name                = var.project_name
  environment                 = var.environment
  vpc_id                      = module.vpc.vpc_id
  vpc_cidr                    = var.vpc_cidr
  kafka_port                  = var.kafka_port
  allow_internal_kafka_access = var.allow_internal_kafka_access
}

module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
}

module "ec2_kafka" {
  source = "./modules/ec2_kafka"

  project_name             = var.project_name
  environment              = var.environment
  subnet_id                = module.vpc.public_subnet_ids[0]
  security_group_id        = module.security_group.security_group_id
  iam_instance_profile     = module.iam.instance_profile_name
  instance_type            = var.instance_type
  root_volume_size         = var.root_volume_size
  kafka_version            = var.kafka_version
  scala_version            = var.scala_version
  topic_name               = var.kafka_topic_name
  topic_partitions         = var.kafka_topic_partitions
  topic_replication_factor = var.kafka_topic_replication_factor
}
