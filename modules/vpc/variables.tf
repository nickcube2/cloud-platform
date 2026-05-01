variable "name" {
  description = "Name prefix applied to all VPC resources"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "cidr_block must be a valid IPv4 CIDR."
  }
}

variable "public_subnet_cidrs" {
  description = "List of CIDRs for public subnets — one per AZ"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of CIDRs for private subnets — one per AZ"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "nat_gateway_count" {
  description = "Number of NAT Gateways. 1 = cost-optimised, match AZ count for full HA"
  type        = number
  default     = 1

  validation {
    condition     = var.nat_gateway_count >= 1
    error_message = "At least one NAT Gateway is required."
  }
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs to CloudWatch"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to merge onto all resources"
  type        = map(string)
  default     = {}
}