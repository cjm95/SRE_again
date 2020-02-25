// 테라폼과 외부 서비스를 연결해주는 기능
provider "aws" {
    profile ="aws_provider"
    region = "ap-northeast-1"
	  access_key =var.aws_access_key
    secret_key = var.aws_secret_key
    
}
 resource "aws_iam_role" "iam_for_lambda" {
   name = "iam_for_lambda"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
 }

resource "aws_iam_policy" "policy" {
  name        = "test-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Sid" :  "" , 
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
        "Sid" :  "" , 
      "Effect": "Allow",
      "Action": [
        "ec2:Start*",
        "ec2:Stop*"
      ],
      "Resource": "*"
    },
    {
        "Sid" :  "" , 
      "Effect":"Allow",
      "Action" :"logs:CreateLogGroup",
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF
}
//////////////////////////////////// start함수 생성//////////////////////////////////
resource "aws_iam_role_policy_attachment" "attach-policies" {
   role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.policy.arn
}

locals {
  lambda_zip_locaion="outputs/welcome.zip"
}
data "archive_file" "welcome"{
  type="zip"
  source_file="welcome.py"
  output_path=local.lambda_zip_locaion
}
resource "aws_lambda_function" "test_lambda1" {
 filename=local.lambda_zip_locaion
  function_name="stop_schedule"
  role=aws_iam_role.iam_for_lambda.arn
  handler="welcome.lambda_handler"
 // source_code_hash=filebase64sha256("welcome.zip")
  runtime="python2.7"
  timeout= "10"
  environment {
    variables = {
      name = "value"
    }
  }
}
// 매일 5분에 인스턴스 꺼볼께여
resource "aws_cloudwatch_event_rule" "every_two_minutes_rule" {
  name="lambda_schedule_rule_stop"
  description="람다로 인스턴스 중지 해볼꺼야!!!"
  schedule_expression="cron(0,5,10,15,20,25,30,35,45,55 * * * ? *)"
}

//Lambda에 타겟팅을 합시다!
resource "aws_cloudwatch_event_target" "lambda_schedule_target" {
  rule=aws_cloudwatch_event_rule.every_two_minutes_rule.name
  arn=aws_lambda_function.test_lambda1.arn
}

// CloudWatch에 대한 권한을 줍시다!
resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
  statement_id="AllowExecutionFromCloudWatch"
  action="lambda:InvokeFunction" //데이터 보호 위해 씁시다
  function_name=aws_lambda_function.test_lambda1.function_name
  principal="events.amazonaws.com"
  source_arn=aws_cloudwatch_event_rule.every_two_minutes_rule.arn
}





 // start함수도 정책이랑 역할은 같이 씀!
locals {
  lambda_zip_locaion2="outputs/bys.zip"
}


data "archive_file" "bys"{
  type="zip"
  source_file="bye.py"
  output_path=local.lambda_zip_locaion2
}

resource "aws_lambda_function" "test_lambda2" { 
  filename=local.lambda_zip_locaion2
  function_name="start_schedule1"
  role=aws_iam_role.iam_for_lambda.arn
  handler="bye.lambda_handler"
 // source_code_hash=filebase64sha256("welcome.zip")
  runtime="python2.7"
  timeout="10"
  environment {
    variables = {
      name = "value"
    }
  }
}

// 인스턴스 꺼지고 1분 뒤에 다시 켬
resource "aws_cloudwatch_event_rule" "every_two_minutes_rule1" {
  name="lambda_schedule_rule_start"
  description="람다로 인스턴스 시작 할꺼야!!!"
  schedule_expression="cron(1,6,11,16,21,26,31,36,41,56 * * * ? *)"
}

//Lambda에 타겟팅을 합시다!
resource "aws_cloudwatch_event_target" "lambda_schedule_target1" {
  rule=aws_cloudwatch_event_rule.every_two_minutes_rule1.name
  arn=aws_lambda_function.test_lambda2.arn
}

// CloudWatch에 대한 권한을 줍시다!
resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda1" {
  statement_id="AllowExecutionFromCloudWatch"
  action="lambda:InvokeFunction" //데이터 보호 위해 씁시다
  function_name=aws_lambda_function.test_lambda2.function_name
  principal="events.amazonaws.com"
  source_arn=aws_cloudwatch_event_rule.every_two_minutes_rule1.arn
}



