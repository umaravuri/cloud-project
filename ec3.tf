provider "aws" {
region = "ap-south-1"
profile = "umaravuri"
}

resource "aws_vpc" "myvpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"
  tags = {
    Name = "narangvpc"
  }
}

resource "aws_subnet" "publicSubnet" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"
tags = {
    Name = "subnet1"
  }
}

resource "aws_subnet" "privateSubnet" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"
tags = {
    Name = "subnet2"
  }
}

resource "aws_internet_gateway" "internetGateway" {
  vpc_id = aws_vpc.myvpc.id
tags = {
    Name = "narang_internetgateway"
  }
}

resource "aws_route_table" "routingTable" {
  vpc_id = aws_vpc.myvpc.id
route {
    
gateway_id = aws_internet_gateway.internetGateway.id
    cidr_block = "0.0.0.0/0"
  }
tags = {
    Name = "narang_RoutingTable"
  }
}

resource "aws_route_table_association" "association" {
  subnet_id      = aws_subnet.publicSubnet.id
  route_table_id = aws_route_table.routingTable.id
}


resource "aws_security_group" "wordpress_sg" {
  depends_on = [ aws_vpc.myvpc ]
  name        = "wp_sg"
  vpc_id      = aws_vpc.myvpc.id
ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0"]
  }
ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
tags = {
    Name = "wordp_sg"
  }
}

resource "aws_security_group" "mysql_sg" {
  depends_on = [ aws_vpc.myvpc ]
  name        = "mysql_sg"
  vpc_id      = aws_vpc.myvpc.id
ingress {
    description = "MYSQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [ aws_security_group.wordpress_sg.id ]
  }
egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
tags = {
    Name = "mysql_sg"
  }
}

resource "aws_instance" "wordpress_os" {
  ami           = "ami-7e257211"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.publicSubnet.id
  vpc_security_group_ids = [ aws_security_group.wordpress_sg.id ]
  key_name = "mynewkey"
tags = {
    Name = "wordpressos"
    }
}

resource "aws_instance" "mysql_os" {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.privateSubnet.id
  vpc_security_group_ids = [ aws_security_group.mysql_sg.id ]
  key_name = "mynewkey"
tags = {
    Name = "mysqlos"
    }
}

resource "null_resource" "nulllocal1"  {
depends_on = [
    aws_instance.wordpress_os ,
    aws_instance.mysql_os ,
  ]
 provisioner "local-exec" {
     command = "start chrome  ${aws_instance.wordpress_os.public_ip}"
   }
}
