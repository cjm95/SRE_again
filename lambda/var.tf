variable "key_name" {
    type    = string
    default = "team22"
}
variable "my_region" {
    type    = string
    default = "ap-northeast-2"
}
variable "db_username" {
    default="root"
    type    = string
}
variable "db_password" {
    type    = string
    default="team2team2"
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
variable "image_id_web" {
    type    = string
    default = "ami-0a93a08544874b3b7"
}
variable "image_id_was1" {
    type    = string
    default = "ami-0a93a08544874b3b7"
}
variable "image_id_was2" {
    type    = string
    default = "ami-0a93a08544874b3b7"
}
variable "target_group_path" {
    type    = string
    default = "/"
}
variable "db_port" {
    type    = string
    default = "3306"
}
