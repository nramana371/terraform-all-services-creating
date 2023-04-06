terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}





# creating the vpc
resource "aws_vpc" "webapp-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "webapp-vpc"
  }
}

#creating subnet

resource "aws_subnet" "webapp-subnet-1a" {
  vpc_id     = aws_vpc.webapp-vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "webapp-subnet-1A"
  }
}


resource "aws_subnet" "webapp-subnet-1b" {
  vpc_id     = aws_vpc.webapp-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "webapp-subnet-1B"
  }
}


resource "aws_subnet" "webapp-subnet-1c" {
  vpc_id     = aws_vpc.webapp-vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1c"

  tags = {
    Name = "webapp-subnet-1C"
  }
}


resource "aws_instance" "webapp-01" {
  ami           = "ami-0ee9d4fdb0fc4a6a6"
  instance_type = "t2.micro"
  key_name =  aws_key_pair.webapp-key-pair.id
  #key_name = "bajji"
  subnet_id = aws_subnet.webapp-subnet-1a.id
  #associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "webapp-01"
  }
}


resource "aws_instance" "webapp-02" {
  ami           = "ami-0ee9d4fdb0fc4a6a6"
  instance_type = "t2.micro"
  key_name =  aws_key_pair.webapp-key-pair.id
  #key_name = "bajji"
  subnet_id = aws_subnet.webapp-subnet-1a.id
  #associate_public_ip_address = true  
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]


  tags = {
    Name = "Webapp-02"
  }
}


resource "aws_key_pair" "webapp-key-pair" {
 key_name   = "webapp-key-pair"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC5dHBTVOM3TDDqMwGdsBwHVOJofhB8j+V8exe3eJF3RZyVT2EiU0V473qmUDlI14DzyaDJOkIZx1Wez+Ri/5Lk32OjQRDZSHSTFhDVyFJvquC0c2jtveysh4NYOhs66w2wLUn6Xv86S1w34EtVXhWmyp0MD6pXyAsIHT82zjhQFttNPc3d5OhyOX8Pit+vnOXlmuep3VCqA66zkZuKE/gvwrgTc/qq99IxfJQwvZH5uclmXWl5DnLAgmnGgI0ZDEMLTi9eCcTAER01iARglI8xosyKivx/DOY7BJKjBmDRxoN6JXDa+FhUcD74Sq2NfuvoOPaQ8c9PMIbaBow9o8Cfj2RHJ/41hxIAgO4OotuYKqDYFK++fNTTA7pWiwaVMU2H2qZoLymznjsfIi7p6f8aHbUU4gblHeErC5bx7GnbkIWZMfgjj+6NKIQDUeOE/OB2ih5jPcQPIfaxwumg73AM0ZReg2PZOU/0q7YNfm14liXaTU80WRDYA8GCbSyFA7c= Bujji@bujji"
}


# Internet GW

resource  "aws_internet_gateway" "webapp-IGW" {
  vpc_id = aws_vpc.webapp-vpc.id

  tags = {
    Name = "Webapp-IGW"
  }
}

# Route Table

resource "aws_route_table" "webapp-RT" {
  vpc_id = aws_vpc.webapp-vpc.id 

 route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.webapp-IGW.id
  }

   tags = {
    Name = "Webapp-RT"
  }
}


resource "aws_route_table_association" "webapp-RT-asso-01" {
  subnet_id      = aws_subnet.webapp-subnet-1a.id
  route_table_id = aws_route_table.webapp-RT.id
}


resource "aws_route_table_association" "webapp-RT-asso-02" {
  subnet_id      = aws_subnet.webapp-subnet-1b.id
  route_table_id = aws_route_table.webapp-RT.id
}

# security group

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.webapp-vpc.id


  ingress {
    description      = "ssh from anywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
  }  

ingress {
    description      = "http from anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
  }  

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ALLOW SSH"
  }
}

# target group creation

resource "aws_lb_target_group" "webapp-TG" {
  name     = "webapp-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.webapp-vpc.id
}


resource "aws_lb_target_group_attachment" "webapp-TG-attach-01" {
  target_group_arn = aws_lb_target_group.webapp-TG.arn
  target_id        = aws_instance.webapp-01.id
  port             = 80
}


resource "aws_lb_target_group_attachment" "webapp-TG-attach-02" {
  target_group_arn = aws_lb_target_group.webapp-TG.arn
  target_id        = aws_instance.webapp-02.id
  port             = 80
}

# LB Listener

resource "aws_lb_listener" "webapp-listener" {
  load_balancer_arn = aws_lb.webapp-LB.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp-TG.arn
 }
}

# Load balanacer

resource "aws_lb" "webapp-LB" {
  name               = "Webapp-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_ssh.id]
  subnets            = [aws_subnet.webapp-subnet-1a.id,aws_subnet.webapp-subnet-1b.id,aws_subnet.webapp-subnet-1c.id]

  enable_deletion_protection = true

  tags = {
    Environment = "production"
  }
}
