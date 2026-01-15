variable "zone" {
  description = "Zone to create the instance in"
  type        = string
  nullable    = false
}

variable "instance_name" {
  description = "Name and hostname of the instance"
  type        = string
  nullable    = false
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to the instance"
  type        = list(string)
  nullable    = false
}

variable "is_nat" {
  description = "Whether the instance should have NAT enabled"
  type        = bool
  nullable    = false
  default     = false
}

variable "subnet_id" {
  description = "Network id"
  type        = string
  nullable    = false
}