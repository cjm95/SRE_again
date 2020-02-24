# AWS CLI Script

# aws cli 설치

sudo apt install awscli

# 이미지 아이디 받아오기(이름& 날짜)

(날짜검색)

aws ec2 describe-images \
 --owners amazon \
 --filters "Name=creation-date,Values=2020-02-20*" \
 --query 'Images[*].[ImageId]'
 
(이름 검색)

aws ec2 describe-images \
 --filters "Name=name,Values=JDK-base-ami 1582292788" \
 --query 'Images[*].[ImageId][0][0]'

aws ec2 describe-images \
 --filters "Name=name,Values=vuejs-base-ami 1582292807" \
 --query 'Images[*].[ImageId][0][0]'

aws ec2 describe-images \
 --filters "Name=name,Values=Web-base-ami 1582292978" \
 --query 'Images[*].[ImageId][0][0]'



# vpc

aws ec2 describe-vpcs \
 --query 'Vpcs[*].[VpcId][*][*]'

# subnet

aws ec2 describe-subnets \
 --query 'Subnets[*].[Tags][*][*][0].Value'

# route-table

aws ec2 describe-route-tables \
 --query 'RouteTables[*].[Tags][*][*][0].Value'

# internet gateway

aws ec2 describe-internet-gateways \
 --query 'InternetGateways[*].[Tags][*][*][0].Value'

# EIP

aws opsworks --region ap-northeast-2 describe-elastic-ips --nat-gateway-id i-06a80b5b1953d5b9c
aws opsworks describe-elastic-ips


# nat-gateways

aws ec2 describe-nat-gateways \
 --query 'NatGateways[*].[Tags][*][*][0].Value'

# rds

aws rds describe-db-instances \
 --query 'DBInstances[*].[DBInstanceIdentifier]'

# ec2

aws ec2 describe-instances \
 --query 'Reservations[*].Instances[*].[Tags][*][*][*].Value'
