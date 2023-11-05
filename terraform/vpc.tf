// VPC and subnet(s)
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.vpc.id

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

  tags = {
    Name = "${var.project}-default-security-group-${random_uuid.val.id}"
  }
}

locals {
  subnet_ids = "${aws_subnet.subnet_private.id}"
  subnet_ids_list = [aws_subnet.subnet_private.id]
}

// ## app-deploy VPC ##
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.project}-vpc-${random_uuid.val.id}"
  }
}

// public subnet
resource "aws_subnet" "subnet_public" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.subnet_public_cidr_block
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
  tags = {
    Name = "${var.project}-subnet-public-${random_uuid.val.id}"
  }
}

// internet gateway
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project}-internet-gateway-${random_uuid.val.id}"
  }
}

// public route table - direct network requests to the Internet Gateway.
resource "aws_route_table" "route_table_public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "${var.project}-route-table-public-${random_uuid.val.id}"
  }
}

// associate the (public) route table with the (public) subnet
resource "aws_route_table_association" "route_table_association_public" {
  subnet_id      = aws_subnet.subnet_public.id
  route_table_id = aws_route_table.route_table_public.id
}

// elastic ip
resource "aws_eip" "eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.internet_gateway]
  tags = {
    Name = "${var.project}-eip-${random_uuid.val.id}"
  }
}

// NAT gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.subnet_public.id

  tags = {
    Name = "${var.project}-nat-gateway-${random_uuid.val.id}"
  }
}

// private subnet
resource "aws_subnet" "subnet_private" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.subnet_private_cidr_block
  map_public_ip_on_launch = false
  availability_zone = "us-east-1a"
  tags = {
    Name = "${var.project}-subnet-private-${random_uuid.val.id}"
  }
}

// private route table - direct traffic from the private subnet to the NAT gateway
resource "aws_route_table" "route_table_private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "${var.project}-route-table-private-${random_uuid.val.id}"
  }
}


// associate the (private) route table with the (private) subnet
resource "aws_route_table_association" "route_table_association_private" {
  subnet_id      = aws_subnet.subnet_private.id
  route_table_id = aws_route_table.route_table_private.id
}

// NACL
resource "aws_default_network_acl" "default_network_acl" {
  default_network_acl_id = aws_vpc.vpc.default_network_acl_id
  subnet_ids             = [aws_subnet.subnet_public.id, aws_subnet.subnet_private.id]

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "${var.project}-default-network-acl-${random_uuid.val.id}"
  }
}