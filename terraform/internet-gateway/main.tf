provider "aws" {}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

data "aws_internet_gateway" "default" {
  filter {
    name   = "attachment.vpc-id"
    values = [aws_default_vpc.default.id]
  }
}

resource "aws_route" "ig_route" {
  route_table_id         = "${aws_default_vpc.default.default_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${data.aws_internet_gateway.default.id}"
}

