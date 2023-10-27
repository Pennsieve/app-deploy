// Default VPC and subnet(s)
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

// TODO - create new security group
resource "aws_default_security_group" "default" {
  vpc_id = aws_default_vpc.default.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_default_subnet" "default_az1" {
  availability_zone = "us-east-1${var.az[count.index]}"

  tags = {
    Name = "Default subnet for us-east-1${var.az[count.index]}"
  }
  count = 6
}

locals {
  subnet_ids = "${aws_default_subnet.default_az1[0].id},${aws_default_subnet.default_az1[1].id},${aws_default_subnet.default_az1[2].id},${aws_default_subnet.default_az1[3].id},${aws_default_subnet.default_az1[4].id},${aws_default_subnet.default_az1[5].id}"
  subnet_ids_list = [aws_default_subnet.default_az1[0].id, aws_default_subnet.default_az1[1].id, aws_default_subnet.default_az1[2].id, aws_default_subnet.default_az1[3].id, aws_default_subnet.default_az1[4].id, aws_default_subnet.default_az1[5].id]
}