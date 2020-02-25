// 프로 바이더 설정 
// 테라폼과 외부 서비스를 연결해주는 기능
provider "aws" {
    profile ="aws_provider"
    region = var.my_region
	  access_key =var.aws_access_key
    secret_key = var.aws_secret_key

}
// VPC 가상 네트워크 설정
resource "aws_vpc" "SRE_vpc" {
  cidr_block="10.10.0.0/16"  
  enable_dns_hostnames="true"  //dns 호스트 네임 활성화
  tags={Name="SRE_vpc"}  //태그 달아줌
  lifecycle{
    create_before_destroy=true
  }
}
// 인터넷 게이트 웨이
resource "aws_internet_gateway" "SRE_igw" {
  vpc_id=aws_vpc.SRE_vpc.id
  tags={Name="SRE_igw"}
}
// 서브넷 설정
// 하나의 네트워크가 분할되어 나눠진 작은 네트워크
// vpc는 SRE_vpc를 사용
// ip주소를 지정하는 방식
resource "aws_subnet" "SRE_public1" {
  vpc_id =aws_vpc.SRE_vpc.id 
  cidr_block="10.10.22.0/24"   
  availability_zone=var.my_az1
  map_public_ip_on_launch=true
  tags={Name="SRE_public1"}
}
resource "aws_subnet" "SRE_public2" {
  vpc_id =aws_vpc.SRE_vpc.id
  cidr_block="10.10.12.0/24"
  availability_zone=var.my_az2
  map_public_ip_on_launch=true
  tags={Name="SRE_public2"}
}
// 바스티온 호스트 위에 public1,public2는 바스티온으로 정의할것
// 네트워크에 접근하기 위한 서버를의미
// VPC 자체를 네트워크 단에서 접근을 제어하고 있으므로
// 퍼블릭 서브넷에 바스티온 호스르를 만들어주고 외부에서 SSH등으로 접근할 수 있는 서버는 이 서버가 유일
// 프라이빗 서브넷이나 VPC 내의 자원에 접근하려면 바스티온 호스트에 접속한 뒤에 다시 접속하는 방식으로 사용
// 이증화해서 AZ마다 한대씩 만들수 있음

resource "aws_subnet" "SRE_private1" {
  vpc_id=aws_vpc.SRE_vpc.id
  cidr_block="10.10.13.0/24"
  availability_zone =var.my_az1
  map_public_ip_on_launch=false
  tags={Name="SRE_private1"}
}
resource "aws_subnet" "SRE_private2" {
  vpc_id=aws_vpc.SRE_vpc.id
  cidr_block="10.10.14.0/24"
  availability_zone =var.my_az2
  map_public_ip_on_launch=false
  tags={Name="SRE_private2"}
}

// eip설정
// 탄력적인 ip를 사용하면 주소를 계정의 다른 인스턴스에 신속하게 다시 매핑하여 인스턴스나 소프트웨어의 오류를 마스킹할 수있음
// 사실 nat gate에서 사용할 eip를 만드는 거임
resource "aws_eip" "SRE_nat_ip" {
  vpc=true

  tags={Name="SRE_nat_ip"}
}
// nat gateway 프라이빗 서브넷에서 외부 인터넷으로 요청을 보낼수 있도록 하는 역할
// 만들어진 eip를 연결
resource "aws_nat_gateway" "SRE_natgw" {
  allocation_id=aws_eip.SRE_nat_ip.id
  subnet_id=aws_subnet.SRE_public1.id
  tags={Name="SRE_natgw"}
}
// 라우트 테이블
// cidr로 표현된 주소로 향하는 패킷을 해당 목적지로 보내버리겠슴
// public은 인터넷게이트웨이를 통해서  인터넷으로 나가게 되어있음
resource "aws_route_table" "SRE_public" {
  vpc_id=aws_vpc.SRE_vpc.id
  route{
    cidr_block="0.0.0.0/0"
    gateway_id=aws_internet_gateway.SRE_igw.id
  }
  tags={Name="SRE_public"}
}
resource "aws_route_table" "SRE_private" {
  vpc_id=aws_vpc.SRE_vpc.id
  route {
    cidr_block="0.0.0.0/0"
    nat_gateway_id=aws_nat_gateway.SRE_natgw.id
  }
  tags={Name="SRE_private"}
}

// route_association 
// 라우팅 테이블과 서브넷 또는 라우팅 테이블과 인터넷 게이트 웨이 또는 가상 게이트 웨이 간의 연결을 만들라는 소스
resource "aws_route_table_association" "SRE_public1" {
  subnet_id =aws_subnet.SRE_public1.id
  route_table_id=aws_route_table.SRE_public.id  
}
resource "aws_route_table_association" "SRE_public2" {
  subnet_id =aws_subnet.SRE_public2.id
  route_table_id=aws_route_table.SRE_public.id
}
resource "aws_route_table_association" "SRE_private1" {
  subnet_id =aws_subnet.SRE_private1.id
  route_table_id=aws_route_table.SRE_private.id
}
resource "aws_route_table_association" "SRE_private2" {
  subnet_id =aws_subnet.SRE_private2.id
  route_table_id=aws_route_table.SRE_private.id
}

// 보안 그룹 설정
resource "aws_security_group" "SRE_sg1" {
  name ="SRE_sg1"
  vpc_id =aws_vpc.SRE_vpc.id
  ingress {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["221.138.49.210/32"]
        description = "my ip"
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
resource "aws_security_group" "SRE_sg2" {
  name ="SRE_sg2"
  vpc_id=aws_vpc.SRE_vpc.id
  ingress{
    from_port =80
    to_port=80
    protocol="tcp"
    cidr_blocks=["10.10.1.98/32"]
    description = "LoadBalancer ip"
  }
  ingress{
    from_port=22
    to_port =22
    protocol="tcp"
    cidr_blocks =["10.10.22.0/24"]
    description = "Bastion Host subnet ip"
  }
  egress{
    from_port =0
    to_port=0
    protocol="-1"
    cidr_blocks=["0.0.0.0/0"]
  }
}
resource "aws_security_group" "SRE_sg3" {
  name        = "SRE_sg3"
    vpc_id      = aws_vpc.SRE_vpc.id
    ingress {
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        cidr_blocks = ["10.10.1.98/32"]
        description = "LoadBalancer ip"
    }
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["10.10.11.0/24"]
    }
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["10.10.22.0/24"]
        description = "Bastion Host subnet ip"
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
}

resource "aws_security_group" "SRE_sg4" {
  name        = "SRE_sg4"
    vpc_id      =aws_vpc.SRE_vpc.id
    ingress {
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        cidr_blocks = ["10.10.1.98/32"]
        description = "LoadBalancer ip"
    }
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["10.10.11.0/24"]
    }
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["10.10.22.0/24"]
        description = "Bastion Host subnet ip"
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
}
resource "aws_security_group" "SRE_sg_rds" {
    name        = "SRE_sg_rds"
    vpc_id      = aws_vpc.SRE_vpc.id
    ingress {
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        cidr_blocks = ["10.10.0.0/16"]
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# resource "aws_network_acl" "SRE_ACL_Private" {
#   vpc_id = aws_vpc.SRE_vpc.id
#   subnet_ids = [aws_subnet.SRE_private1.id, aws_subnet.SRE_private2.id]

#   egress {
#     protocol   = "tcp"
#     rule_no    = 200
#     action     = "allow"
#     cidr_block = "10.3.0.0/18"
#     from_port  = 443
#     to_port    = 443
#   }

#   ingress {
#     protocol   = "tcp"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = "10.10.0.0/16"
#     from_port  = 22
#     to_port    = 22
#   }
# ingress {
#     protocol   = "tcp"
#     rule_no    = 22
#     action     = "allow"
#     cidr_block = "10.10.1.98/32"
#     from_port  = 22
#     to_port    = 22
#   }
#   ingress {
#     protocol   = "tcp"
#     rule_no    = 1000
#     action     = "allow"
#     cidr_block = "10.10.1.98/32"
#     from_port  = 1024
#     to_port    = 65535
#   }
#   ingress { 
#     protocol   = "tcp"
#     rule_no    = 200
#     action     = "allow"
#     cidr_block = "10.10.0.0/16"
#     from_port  = 3306
#     to_port    = 3306
#   }

#   tags = {
#     Name = "SRE_ACL_Private"
#   }
# }

# resource "aws_db_subnet_group" "SRE_rds_sg" {
#     name = "sre-db-sg"
#     subnet_ids = [aws_subnet.SRE_private1.id, aws_subnet.SRE_private2.id]
# }
# resource "aws_db_instance" "SRE_rds" {
#     allocated_storage   = 20
#     engine              = "mysql"
#     engine_version      = "5.7.26"
#     instance_class      = "db.t2.micro"
#     username            = var.db_username
#     password            = var.db_password
#     port                = var.db_port
#     db_subnet_group_name = aws_db_subnet_group.SRE_rds_sg.name
#     vpc_security_group_ids = [aws_security_group.SRE_sg_rds.id]
#     skip_final_snapshot = true
#     multi_az		= true
# }

//SRE_public1 객체?를 바스티온 설정
resource "aws_instance" "SRE_bastion" {
  instance_type ="t2.micro"
  ami =var.web_ami_id
  key_name =var.key_name
  vpc_security_group_ids =[aws_security_group.SRE_sg1.id]
  subnet_id =aws_subnet.SRE_public1.id
  associate_public_ip_address=true   //퍼블릭 설정
  tags ={Name="SRE_bastion"}
}
//SRE_private1을 웹 인스턴스 설정
resource "aws_instance" "SRE_web1" {
  instance_type="t2.micro"
  ami=var.web_ami_id
  key_name=var.key_name
  vpc_security_group_ids=[aws_security_group.SRE_sg2.id]
  subnet_id=aws_subnet.SRE_private1.id
  associate_public_ip_address=false
  tags={Name="SRE_web1"}
}
resource "aws_instance" "SRE_web2" {
  instance_type           = "t2.micro"
    ami                     = var.web_ami_id
    key_name                = var.key_name
    vpc_security_group_ids  = [aws_security_group.SRE_sg2.id]
    subnet_id               = aws_subnet.SRE_private2.id
    associate_public_ip_address = false
    tags = { Name = "SRE_web2(auto stop)"  }
}
resource "aws_instance" "SRE_was1" {
  instance_type           = "t2.micro"
    ami                     = var.api_ami_id
    key_name                = var.key_name
    vpc_security_group_ids  = [aws_security_group.SRE_sg3.id]
    subnet_id               = aws_subnet.SRE_private1.id
    associate_public_ip_address = false
    tags = {  Name = "SRE_was1"  }
}
resource "aws_instance" "SRE_was2" {
    instance_type           = "t2.micro"
    ami                     = var.api_ami_id
    key_name                = var.key_name
    vpc_security_group_ids  = [aws_security_group.SRE_sg3.id]
    subnet_id               = aws_subnet.SRE_private2.id
    associate_public_ip_address = false
    tags = { Name = "SRE_was2"}
}
resource "aws_instance" "SRE_was3" {
    instance_type           = "t2.micro"
    ami                     = var.ui_ami_id
    key_name                = var.key_name
    vpc_security_group_ids  = [aws_security_group.SRE_sg4.id]
    subnet_id               = aws_subnet.SRE_private1.id
    associate_public_ip_address = false
    tags = { Name = "SRE_was3(auto stop)"}
}
resource "aws_instance" "SRE_was4" {
    instance_type           = "t2.micro"
    ami                     = var.ui_ami_id
    key_name                = var.key_name
    vpc_security_group_ids  = [aws_security_group.SRE_sg4.id]
    subnet_id               = aws_subnet.SRE_private2.id
    associate_public_ip_address = false
    tags = { Name = "SRE_was4"}
}

resource "aws_lb" "SRE_web" {
  name            = "SREexternal"
  internal        = false
  idle_timeout    = "300"
  load_balancer_type = "application"
  security_groups = [aws_security_group.SRE_sg2.id]
  subnets = [aws_subnet.SRE_private1.id, aws_subnet.SRE_private2.id]
  enable_deletion_protection = false

  tags = {
    Name = "SRE_external"
  }
}

resource "aws_lb" "SRE_was" {
  name            = "SREinternal"
  internal        = true
  idle_timeout    = "300"
  load_balancer_type = "application"
  subnets         = [aws_subnet.SRE_private1.id, aws_subnet.SRE_private2.id]
  security_groups = [aws_security_group.SRE_sg3.id,aws_security_group.SRE_sg4.id]
  enable_deletion_protection = false

  tags = {
    Name = "SRE_internal"
  }
}
resource "aws_lb_listener" "SRE_web" {
  load_balancer_arn = "${aws_lb.SRE_web.arn}"
  port              = "80"
  protocol          = "HTTP"
  # ssl_policy        = "ELBSecurityPolicy-2016-08"
  # certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.SRE_web.arn}"
  }

}
resource "aws_lb_listener" "SRE_was" {
  load_balancer_arn = "${aws_lb.SRE_was.arn}"
  port              = "8080"
  protocol          = "HTTP"
  # ssl_policy        = "ELBSecurityPolicy-2016-08"
  # certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.SRE_was.arn}"
  }

}

#  Security Group for ALB
resource "aws_security_group" "SRE_external-alb" {
    name = "SRE_external-load-balancer"
    description = "allow tcp to SRE_external Load Balancer (ALB)"
    vpc_id = aws_vpc.SRE_vpc.id
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["10.10.1.98/32"]
    }
        ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
        egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
        egress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "SRE_external"
    }
}

#  Security Group for ALB
resource "aws_security_group" "SRE_internal-alb" {
    name = "SRE_internal-load-balancer"
    description = "allow tcp to SRE_internal Load Balancer (ALB)"
    vpc_id = aws_vpc.SRE_vpc.id
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["10.10.1.98/32"]
    }
        ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
        egress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
        egress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "SRE_internal"
    }
}



# alb target group 설정
resource "aws_alb_target_group" "SRE_web" {
  name     = "SRE-web"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.SRE_vpc.id
 health_check {
    healthy_threshold   = 10
    unhealthy_threshold = 2
    timeout             = 5
    path                = var.target_group_path
    interval            = 10
    port                = 80
  }
  tags = {Name   = "SRE_web" }
}
resource "aws_alb_target_group" "SRE_was" {
  name     = "SRE-was"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.SRE_vpc.id
 health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    path                = var.target_group_path
    interval            = 30
    port                = 8080
  }
  tags = {Name  = "SRE_was"}
}
# resource "aws_alb_target_group" "SRE_was2" {
#   name     = "SRE-was"
#   port     = 8080
#   protocol = "HTTP"
#   vpc_id   = aws_vpc.SRE_vpc.id
#  health_check {
#     healthy_threshold   = 5
#     unhealthy_threshold = 2
#     timeout             = 5
#     path                = var.target_group_path
#     interval            = 30
#     port                = 8080
#   }
#   tags = {Name  = "SRE_was2"}
# }

## alb에 instance 연결
resource "aws_alb_target_group_attachment" "SRE_web1" {
  target_group_arn = aws_alb_target_group.SRE_web.arn
  target_id        = aws_instance.SRE_web1.id
  port             = 80
}
resource "aws_alb_target_group_attachment" "SRE_web2" {
  target_group_arn = aws_alb_target_group.SRE_web.arn
  target_id        = aws_instance.SRE_web2.id
  port             = 80
}
resource "aws_alb_target_group_attachment" "SRE_was1" {
  target_group_arn = aws_alb_target_group.SRE_was.arn
  target_id        = aws_instance.SRE_was1.id
  port             = 8080
}
resource "aws_alb_target_group_attachment" "SRE_was2" {
  target_group_arn = aws_alb_target_group.SRE_was.arn
  target_id        = aws_instance.SRE_was2.id
  port             = 8080
}
# resource "aws_alb_target_group_attachment" "SRE_was3" {
#   target_group_arn = aws_alb_target_group.SRE_was2.arn
#   target_id        = aws_instance.SRE_was3.id
#   port             = 8080
# }
# resource "aws_alb_target_group_attachment" "SRE_was4" {
#   target_group_arn = aws_alb_target_group.SRE_was2.arn
#   target_id        = aws_instance.SRE_was4.id
#   port             = 8080
# }

#####################
# Autoscaling group #
#####################
//data "aws_availability_zones" "all" {}
resource "aws_autoscaling_group" "asg_web1" {
  launch_configuration=aws_launch_configuration.alc_web1.id
  availability_zones = ["ap-northeast-2a","ap-northeast-2c"]
  min_size=0
  max_size=6
 
 health_check_grace_period = 300
  health_check_type         = "ELB" 
  tag{
    key="Name"
    value="terraform-asg-example1"
    propagate_at_launch=true
  }
}
resource "aws_autoscaling_group" "asg_was1" {
  launch_configuration=aws_launch_configuration.alc_was1.id
  availability_zones = ["ap-northeast-2a","ap-northeast-2c"]
  min_size=0
  max_size=6
 
 health_check_grace_period = 300
  health_check_type         = "ELB" 
  tag{
    key="Name"
    value="terraform-asg-example2"
    propagate_at_launch=true
  }
}
resource "aws_autoscaling_group" "asg_was2" {
  launch_configuration=aws_launch_configuration.alc_was2.id
  availability_zones = ["ap-northeast-2a","ap-northeast-2c"]
  min_size=0
  max_size=6
 
 health_check_grace_period = 300
  health_check_type         = "ELB" 
  tag{
    key="Name"
    value="terraform-asg-example3"
    propagate_at_launch=true
  }
}

// auto Scaling이란?
// 애플리케이션의 로드를 처리할 수 있는 정확한 수의 ec2인스턴스를 보유하도록 보장할 수 있음
// EC2 인스턴스의 트래픽에 따라서 자동으로 추가적인 EC2 인스턴스를 생성 및 삭제해서 최적의 서비스를 제공
// 보통 cloudwatch와 ELB와 함께 생성
// CloudWatch는 인스턴스의 CPU 사용률,네트워크 사용량 등을 체크, ELB와 연결되어 트래픽을 분산 시킴
// 1. Auto Scailing group이라는 ec2 인스턴스 모음을 생성
// 2. 각 auto Scailing group의 최소, 최대 인스턴스 수를 지정(그룹의 크기가 이 값 아래로(위로) 내려(올라)가지 않음)

// auto scaling 타겟 그룹 설정
resource "aws_autoscaling_attachment" "asg_attachment_web" {
  autoscaling_group_name = aws_autoscaling_group.asg_web1.id
  alb_target_group_arn   = aws_alb_target_group.SRE_web.arn
}
resource "aws_autoscaling_attachment" "asg_attachment_was1" {
  autoscaling_group_name = aws_autoscaling_group.asg_was1.id
  alb_target_group_arn   = aws_alb_target_group.SRE_was.arn
}
resource "aws_autoscaling_attachment" "asg_attachment_was2" {
  autoscaling_group_name = aws_autoscaling_group.asg_was2.id
  alb_target_group_arn   = aws_alb_target_group.SRE_was.arn
}

########################
# Launch configuration #
########################
resource "aws_launch_configuration" "alc_web1" {
  image_id=var.web_ami_id
  instance_type="t2.micro"
  lifecycle{
    create_before_destroy=true
  }
}
resource "aws_launch_configuration" "alc_was1" {
  image_id=var.api_ami_id
  instance_type="t2.micro"
  lifecycle{
    create_before_destroy=true
  }
}
resource "aws_launch_configuration" "alc_was2" {
  image_id=var.ui_ami_id
  instance_type="t2.micro"
  lifecycle{
    create_before_destroy=true
  }
}
