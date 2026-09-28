variable "project_name" {
  description = "Name of the project, used for resource naming and tags"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)"
  type        = string
}
