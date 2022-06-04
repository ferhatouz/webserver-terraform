variable "vpc_cidr" {
  description = "Please provide a cidr_block to deploy VPC"
  type        = string
  default     = ""
}
variable "web-subnet-1" {
  description = "Please provide a web-subnet-1_cidr to deploy VPC"
  type        = string
  default     = ""
}
variable "web-subnet-2" {
  description = "Please provide a web-subnet-1_cidr to deploy VPC"
  type        = string
  default     = ""
}
variable "app-subnet-1" {
  description = "Please provide a web-subnet-1_cidr to deploy VPC"
  type        = string
  default     = ""
}
variable "app-subnet-2" {
  description = "Please provide a web-subnet-1_cidr to deploy VPC"
  type        = string
  default     = ""
}
variable "db-subnet-1" {
  description = "Please provide a web-subnet-1_cidr to deploy VPC"
  type        = string
  default     = ""
}
variable "db-subnet-2" {
  description = "Please provide a web-subnet-1_cidr to deploy VPC"
  type        = string
  default     = ""
}
variable "az1" {
  description = "Please provide a avaibility zone"
  type        = string
  default     = ""
}
variable "az2" {
  description = "Please provide a avaibility zone"
  type        = string
  default     = ""
}
variable "zone_id" {
  description = "Provide zone id"
  type        = string
  default     = ""

}
