Copy-Item "C:\cloudwatch.json" -Destination "C:\Program Files\Amazon\SSM\Plugins\awsCloudWatch\AWS.EC2.Windows.CloudWatch.json"
Restart-Service AmazonSSMAgent
