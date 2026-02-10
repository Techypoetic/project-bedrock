variable "vpc_name" {
  description = "Name of the VPC"
  type        = string

  validation {
    condition     = length(trimspace(var.vpc_name)) > 0
    error_message = "vpc_name must not be empty."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block (e.g., 10.0.0.0/16)."
  }
}

variable "azs" {
  description = "Availability Zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]

  validation {
    condition     = length(var.azs) >= 2
    error_message = "azs must contain at least 2 Availability Zones (e.g., us-east-1a, us-east-1b)."
  }

  validation {
    condition     = length(var.azs) == length(distinct(var.azs))
    error_message = "azs must not contain duplicate Availability Zones."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "At least 2 public subnets are required for high availability."
  }

  validation {
    condition     = alltrue([for c in var.public_subnet_cidrs : can(cidrhost(c, 0))])
    error_message = "All public_subnet_cidrs must be valid IPv4 CIDR blocks."
  }

  validation {
    condition     = length(var.public_subnet_cidrs) == length(distinct(var.public_subnet_cidrs))
    error_message = "public_subnet_cidrs must not contain duplicate CIDR blocks."
  }

  validation {
    condition     = length(var.public_subnet_cidrs) == length(var.azs)
    error_message = "public_subnet_cidrs length must match azs length."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "At least 2 private subnets are required for high availability."
  }

  validation {
    condition     = alltrue([for c in var.private_subnet_cidrs : can(cidrhost(c, 0))])
    error_message = "All private_subnet_cidrs must be valid IPv4 CIDR blocks."
  }

  validation {
    condition     = length(var.private_subnet_cidrs) == length(distinct(var.private_subnet_cidrs))
    error_message = "private_subnet_cidrs must not contain duplicate CIDR blocks."
  }

  validation {
    condition     = length(var.private_subnet_cidrs) == length(var.azs)
    error_message = "private_subnet_cidrs length must match azs length."
  }
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateways for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets (cost savings)"
  type        = bool
  default     = false
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
