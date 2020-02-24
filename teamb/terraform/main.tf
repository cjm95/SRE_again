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
    cidr_blocks =["10.10.11.0/24"]
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

resource "aws_network_acl" "SRE_ACL_Private" {
  vpc_id = aws_vpc.SRE_vpc.id
  subnet_ids = [aws_subnet.SRE_private1.id, aws_subnet.SRE_private2.id]

  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "10.3.0.0/18"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.10.0.0/16"
    from_port  = 22
    to_port    = 22
  }
ingress {
    protocol   = "tcp"
    rule_no    = 22
    action     = "allow"
    cidr_block = "10.10.1.98/32"
    from_port  = 22
    to_port    = 22
  }
  ingress {
    protocol   = "tcp"
    rule_no    = 1000
    action     = "allow"
    cidr_block = "10.10.1.98/32"
    from_port  = 1024
    to_port    = 65535
  }
  ingress { 
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "10.10.0.0/16"
    from_port  = 3306
    to_port    = 3306
  }

  tags = {
    Name = "SRE_ACL_Private"
  }
}

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
