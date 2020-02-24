variable "key_name" {
    type    = string
    default = "Auto-teamB-SRE"
}
variable "my_region" {
    type    = string
    default = "ap-northeast-2"
}
variable "my_az1" {
    type    = string
    default = "ap-northeast-2a"
}
variable "my_az2" {
    type    = string
    default = "ap-northeast-2c"
}
variable "db_username" {
    default="root"
    type    = string
}
variable "db_password" {
    type    = string
    description = "RDS DB instance password should be More than 8 letters."
    default="{{db_password}}"
}
variable "aws_access_key" {
    type    = string
    default="{{aws_access_key}}"
    description = "Your access key"
}
variable "aws_secret_key" {
    type    = string
    default="{{aws_secret_key}}"
    description = "Your secret key"
}
variable "web_ami_id" {
    type    = string
    default = "{{web_ami_id}}"
    # default = "ami-035ce95e9e510168a"
}
variable "api_ami_id" {
    type    = string
    default = "{{api_ami_id}}"
    # default = "ami-035ce95e9e510168a"
}
variable "ui_ami_id" {
    type    = string
    default = "{{ui_ami_id}}"
    # default = "ami-035ce95e9e510168a"
}
variable "target_group_path" {
    type    = string
    default = "/"
}
variable "db_port" {
    type    = string
    default = "3306"
}
