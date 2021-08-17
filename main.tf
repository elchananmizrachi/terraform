terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = "= 1.0.4"
}

provider "aws" {
  profile = "default"
  region  = "us-east-2"
  access_key = "*******"
  secret_key = "*******"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/24"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "Main"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route = [
    {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.gw.id
      carrier_gateway_id = ""
      destination_prefix_list_id = ""
      egress_only_gateway_id = ""
      instance_id = ""
      ipv6_cidr_block = ""
      local_gateway_id = ""
      nat_gateway_id =""
      network_interface_id = ""
      transit_gateway_id = ""
      vpc_endpoint_id = ""
      vpc_peering_connection_id = ""
    }
  ]
  tags = {
    Name = "main"
  }

}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow http traffic"
  vpc_id     = aws_vpc.main.id

  ingress = [
    {
      description      = "http allow"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = false
    }
  ]
  egress = [
    {
      description      = "http allow"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = false
    }
  ]
  tags = {
    Name = "allow_http"
  }
}

resource "aws_security_group" "allow_https" {
  name        = "allow_https"
  description = "Allow https traffic"
  vpc_id     = aws_vpc.main.id

  ingress = [
    {
      description      = "https allow"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks =[]
      prefix_list_ids = []
      security_groups = []
      self = false
    }
  ]
  egress = [
    {
      description      = "https allow"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids = []
      security_groups = []
      self = false
    }
  ]
  tags = {
    Name = "allow_https"
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow ssh connection"
  vpc_id     = aws_vpc.main.id

  ingress = [
    {
      description      = "ssh allow"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = false
    }
  ]
  egress = [
    {
      description      = "ssh allow"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = false
    }
  ]
  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_instance" "test-ec2" {
  ami = "ami-00399ec92321828f5"
  key_name = "elchanan"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id, aws_security_group.allow_http.id]
  tags = {
    Name = "test-ec2"
  }
}

resource "aws_instance" "nginx-srv" {
  ami = "ami-00399ec92321828f5"
  key_name = "elchanan"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.main.id
  user_data = file("nginx.sh")
  vpc_security_group_ids = [aws_security_group.allow_ssh.id, aws_security_group.allow_http.id]
  tags = {
    Name = "nginx-srv"
  }
}

resource "aws_eip" "nginx-static" {
  instance = aws_instance.nginx-srv.id
  vpc = true
}

