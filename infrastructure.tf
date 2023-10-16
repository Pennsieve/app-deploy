provider "aws" {}

resource "aws_instance" "myec2" {
    ami = "ami-041feb57c611358bd"
    instance_type = "t2.micro"
}