import boto3
region = 'ap-northeast-1'
instances = ['i-071dca6f6f0b6c08f']

def lambda_handler(event, context):
    ec2 = boto3.client('ec2', region_name=region)
    ec2.start_instances(InstanceIds=instances)
    print 'started your instances: ' + str(instances)