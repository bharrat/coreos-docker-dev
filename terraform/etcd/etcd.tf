provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
}

resource "aws_instance" "etcd-a-01" {
    ami = "${lookup(var.amis, var.aws_region)}"
    instance_type = "${var.aws_instance_type}"
    key_name = "${var.aws_ec2_keypair}"
    security_groups = [ "${var.security_groups}" ]
    # associate_public_ip_address = true: 
    # Error launching source instance: Network interfaces and an instance-level private IP address may not be specified on the same 
    # request (InvalidParameterCombination). Workaround: turn on associate_public_ip_address for each subnet
    private_ip = "${var.private_ip.us-west-2a}"
    subnet_id = "${var.subnet.us-west-2a}"
    iam_instance_profile = "registry-profile"
    user_data = <<USER_DATA
    ${file("cloud-config/etcd.yaml")}
USER_DATA
    
    provisioner "local-exec" {
        # command = "echo ${aws_instance.etcd-a-01.public_ip} > etcd.txt; echo ${aws_instance.etcd-a-01.id}"
        command = "/usr/local/bin/aws ec2 create-tags --resources ${aws_instance.etcd-a-01.id} --tags Key=Name,Value=docker-etcd-a-01"
    }
}


# Create other etcd instance of the etcd on an t1.micro node
resource "aws_instance" "etcd-b-01" {
    depends_on = [ "aws_instance.etcd-a-01" ]
    ami = "${lookup(var.amis, var.aws_region)}"
    instance_type = "${var.aws_instance_type}"
    key_name = "${var.aws_ec2_keypair}"
    security_groups = [ "${var.security_groups}" ]
    private_ip = "${var.private_ip.us-west-2b}"
    subnet_id = "${var.subnet.us-west-2b}"
    iam_instance_profile = "registry-profile"
    user_data = <<USER_DATA
    ${file("cloud-config/etcd-join.yaml")}
USER_DATA
    
    provisioner "local-exec" {
        command = "/usr/local/bin/aws ec2 create-tags --resources ${aws_instance.etcd-b-01.id} --tags Key=Name,Value=docker-etcd-b-01"
    }
}

# Create other etcd instance of the etcd on an t1.micro node
resource "aws_instance" "etcd-c-01" {
    depends_on = [ "aws_instance.etcd-a-01" ]
    ami = "${lookup(var.amis, var.aws_region)}"
    instance_type = "${var.aws_instance_type}"
    key_name = "${var.aws_ec2_keypair}"
    security_groups = [ "${var.security_groups}" ]
    private_ip = "${var.private_ip.us-west-2c}"
    subnet_id = "${var.subnet.us-west-2c}"
   
    iam_instance_profile = "registry-profile"
    user_data = <<USER_DATA
    ${file("cloud-config/etcd-join.yaml")}
USER_DATA
    
    provisioner "local-exec" {
        command = "/usr/local/bin/aws ec2 create-tags --resources ${aws_instance.etcd-c-01.id} --tags Key=Name,Value=docker-etcd-c-01"
    }
}
