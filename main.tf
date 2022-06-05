resource "aws_vpc" "my-vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "Webserver VPC"
  }
}

# Create Web Public Subnet
resource "aws_subnet" "web-subnet-1" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = var.web-subnet-1
  availability_zone       = var.az1
  map_public_ip_on_launch = true

  tags = {
    Name = "Web-1a"
  }
}

resource "aws_subnet" "web-subnet-2" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = var.web-subnet-2
  availability_zone       = var.az2
  map_public_ip_on_launch = true

  tags = {
    Name = "Web-2b"
  }
}

# Create Application Private Subnet
resource "aws_subnet" "app-subnet-1" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = var.app-subnet-1
  availability_zone       = var.az1
  map_public_ip_on_launch = false

  tags = {
    Name = "Application-1a"
  }
}

resource "aws_subnet" "app-subnet-2" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = var.app-subnet-2
  availability_zone       = var.az2
  map_public_ip_on_launch = false

  tags = {
    Name = "Application-2b"
  }
}

# Create Database Private Subnet
resource "aws_subnet" "db-subnet-1" {
  vpc_id            = aws_vpc.my-vpc.id
  cidr_block        = var.db-subnet-1
  availability_zone = var.az1

  tags = {
    Name = "Database-1a"
  }
}

resource "aws_subnet" "db-subnet-2" {
  vpc_id            = aws_vpc.my-vpc.id
  cidr_block        = var.db-subnet-2
  availability_zone = var.az2

  tags = {
    Name = "Database-2b"
  }
}
# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "Webserver IGW"
  }
}
#Elastic IP
resource "aws_eip" "bar" {
  vpc = true
}
#Create a NatGateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.bar.id
  subnet_id     = aws_subnet.web-subnet-1.id
  tags = {
    "Name" = "webser NGW"
  }
}
#Create Route Table for Natgateway
resource "aws_route_table" "nat" {
  vpc_id = aws_vpc.my-vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
}
# Create Web Subnet association with Nat route table
resource "aws_route_table_association" "NatGatewaya1" {
  subnet_id      = aws_subnet.app-subnet-1.id
  route_table_id = aws_route_table.nat.id
}
resource "aws_route_table_association" "NatGatewaya2" {
  subnet_id      = aws_subnet.app-subnet-2.id
  route_table_id = aws_route_table.nat.id
}
resource "aws_route_table_association" "NatGatewayd1" {
  subnet_id      = aws_subnet.db-subnet-1.id
  route_table_id = aws_route_table.nat.id
}
resource "aws_route_table_association" "NatGatewayd2" {
  subnet_id      = aws_subnet.db-subnet-2.id
  route_table_id = aws_route_table.nat.id
}
# Create Web layber route table
resource "aws_route_table" "web-rt" {
  vpc_id = aws_vpc.my-vpc.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "WebRT"
  }
}
# Create Web Subnet association with Web route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.web-subnet-1.id
  route_table_id = aws_route_table.web-rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.web-subnet-2.id
  route_table_id = aws_route_table.web-rt.id
}
#Create EC2 Instance
resource "aws_instance" "webserver1" {
  ami                    = "ami-0d5eff06f840b45e9"
  instance_type          = "t2.micro"
  availability_zone      = var.az1
  vpc_security_group_ids = [aws_security_group.webserver-sg.id]
  subnet_id              = aws_subnet.web-subnet-1.id
  user_data              = file("apache.sh")

  tags = {
    Name = "Web Server"
  }
}
resource "aws_instance" "webserver2" {
  ami                    = "ami-0d5eff06f840b45e9"
  instance_type          = "t2.micro"
  availability_zone      = var.az2
  vpc_security_group_ids = [aws_security_group.webserver-sg.id]
  subnet_id              = aws_subnet.web-subnet-2.id
  user_data              = file("apache.sh")

  tags = {
    Name = "Web Server"
  }
}
# Create Web Security Group
resource "aws_security_group" "web-sg" {
  name        = "Web-SG"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.my-vpc.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Web-SG"
  }
}

# Create Web Server Security Group
resource "aws_security_group" "webserver-sg" {
  name        = "Webserver-SG"
  description = "Allow inbound traffic from ALB"
  vpc_id      = aws_vpc.my-vpc.id

  ingress {
    description     = "Allow traffic from web layer"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Webserver-SG"
  }
}

# Create Database Security Group
resource "aws_security_group" "database-sg" {
  name        = "Database-SG"
  description = "Allow inbound traffic from application layer"
  vpc_id      = aws_vpc.my-vpc.id

  ingress {
    description     = "Allow traffic from application layer"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.webserver-sg.id]
  }

  egress {
    from_port   = 32768
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Database-SG"
  }
}
#Create  a Load balancer for external
resource "aws_lb" "external-elb" {
  name               = "External-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web-sg.id]
  subnets            = [aws_subnet.web-subnet-1.id, aws_subnet.web-subnet-2.id]
}
#Create  a Load balancer target group
resource "aws_lb_target_group" "external-elb" {
  name     = "ALB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my-vpc.id
}
#Create  a Load balancer target group attachment 
resource "aws_lb_target_group_attachment" "external-elb1" {
  target_group_arn = aws_lb_target_group.external-elb.arn
   target_id        = aws_instance.webserver2.id
  port             = 80

  depends_on = [aws_instance.webserver1, ]
}

resource "aws_lb_target_group_attachment" "external-elb2" {
  target_group_arn = aws_lb_target_group.external-elb.arn
  target_id        = aws_instance.webserver2.id
  port             = 80

  depends_on = [aws_instance.webserver2,]
}

resource "aws_lb_listener" "external-elb" {
  load_balancer_arn = aws_lb.external-elb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external-elb.arn
  }
}
#Create Network Load Balancer for internal
resource "aws_lb" "internal-lb" {
  name               = "internal"
  load_balancer_type = "network"

  subnet_mapping {
    subnet_id            = aws_subnet.app-subnet-1.id
    private_ipv4_address = "10.0.1.15"
  }

  subnet_mapping {
    subnet_id            = aws_subnet.app-subnet-1.id
    private_ipv4_address = "10.0.2.15"
  }
}
#Create a Auto-Scaling Template for web
resource "aws_launch_configuration" "web" {
  name_prefix     = "web-launch"
  image_id        = "ami-0022f774911c1d690"
  instance_type   = "t2.micro"
  user_data       = file("apache.sh")
  security_groups = [aws_security_group.web-sg.id]

  lifecycle {
    create_before_destroy = true
  }
}
#Create a Auto-Scaling Template for App
resource "aws_launch_configuration" "app" {
  name_prefix     = "app-launch"
  image_id        = "ami-0022f774911c1d690"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.webserver-sg.id]

  lifecycle {
    create_before_destroy = true
  }
}
#Set a Auto-Scaling-Group for web
resource "aws_autoscaling_group" "web-asg" {
  min_size             = 2
  max_size             = 5
  desired_capacity     = 2
  launch_configuration = aws_launch_configuration.web.name
  vpc_zone_identifier  = [aws_subnet.web-subnet-1.id, aws_subnet.web-subnet-1.id]
}
#Attach auto-scaling-group to LB for web
resource "aws_autoscaling_attachment" "asg_attachment_external" {
  autoscaling_group_name = aws_autoscaling_group.web-asg.id
  elb                    = aws_lb.external-elb.id
}
#Set a Auto-Scaling-Group for app
resource "aws_autoscaling_group" "app-asg" {
  min_size             = 2
  max_size             = 5
  desired_capacity     = 2
  launch_configuration = aws_launch_configuration.web.name
  vpc_zone_identifier  = [aws_subnet.app-subnet-1.id, aws_subnet.app-subnet-2.id]
}
#Attach auto-scaling-group to LB for app
resource "aws_autoscaling_attachment" "asg_attachment_internal" {
  autoscaling_group_name = aws_autoscaling_group.app-asg.id
  elb                    = aws_lb.internal-lb.id
}
#Create Database Instance

resource "aws_db_instance" "default" {
  allocated_storage      = 10
  db_subnet_group_name   = aws_db_subnet_group.default.id
  engine                 = "mysql"
  engine_version         = "8.0.20"
  instance_class         = "db.t2.micro"
  multi_az               = true
  db_name                = "mydb"
  username               = "webserver"
  password               = "password"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.database-sg.id]
}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = [aws_subnet.db-subnet-1.id, aws_subnet.db-subnet-2.id]

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_route53_record" "www" {
  zone_id = var.zone_id
  name    = "project.ferhatouz.com"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.external-elb.dns_name]
}
output "lb_dns_name" {
  value = aws_lb.external-elb.dns_name

}