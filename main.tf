provider "aws" {
    region = "eu-north-1"
}

resource "aws_vpc" "BezogiaStgVpc" {
  cidr_block = "15.0.0.0/16"
}

resource "aws_instance" "myFirsEc2" {
    ami = "ami-04cdc91e49cb06165"
    instance_type = "t3.micro"
}