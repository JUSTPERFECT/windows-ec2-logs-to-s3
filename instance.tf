data "aws_ami" "amazon_windows_2012R2" {
 most_recent = true
 owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2012-R2_RTM-English-64Bit-Base-*"]
  }
}
#resource "aws_iam_instance_profile" "instance_profile" {
#name="instance_profile"
#role="AmazonEC2RoleforSSM"
#}
resource "aws_instance" "winrm" {

 instance_type = "${var.ins_type}"
 ami           = "${data.aws_ami.amazon_windows_2012R2.image_id}"
 iam_instance_profile="${var.iam_role}"
 subnet_id="${var.vpc_subnet_id}"
 key_name = "${var.key_name}"
 vpc_security_group_ids=["${aws_security_group.winrm_sg.id}"]

user_data = <<EOF
<powershell>

  # Set Administrator password

 $admin = [adsi]("WinNT://./administrator, user")

 $admin.psbase.invoke("SetPassword", "${var.admin_password}")

winrm quickconfig -q
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="300"}'
winrm set winrm/config '@{MaxTimeoutms="180000"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
netsh advfirewall firewall add rule name="WinRM 5985" protocol=TCP dir=in profile=any localport=5985 remoteip=any localip=any action=allow
netsh advfirewall firewall add rule name="WinRM 5986" protocol=TCP dir=in profile=any localport=5986 remoteip=any localip=any action=allow
net stop winrm
sc.exe config winrm start=auto
net start winrm
</powershell>
EOF
provisioner "file" {

source ="cloudwatch.json"

destination="C:\\cloudwatch.json"

}

provisioner "file" {

source="cloudwatch.ps1"

destination="C:\\cloudwatch.ps1"

}

provisioner "remote-exec" {

inline = [

"powershell.exe -Executionpolicy Unrestricted -File C:\\cloudwatch.ps1",

]

}
connection {

    type     = "winrm"

    user     = "Administrator"

    password = "${var.admin_password}"

    timeout  = "30m"

  }


}
