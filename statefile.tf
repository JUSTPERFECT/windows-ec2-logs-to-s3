terraform {
        required_version = "> 0.9.0"
        backend "s3" {
                bucket ="mybucket623"
                key    = "bootstrap-testing-ec2-windows.tfstate"
                region = "us-west-2"
                encrypt = "true"
        }
}
