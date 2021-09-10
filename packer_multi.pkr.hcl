#init packer with the required plugins - AMI management is optional
packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/amazon"
    }
    amazon-ami-management = {
      version = ">= 1.0.0"
      source  = "github.com/wata727/amazon-ami-management"
    }
  }
}

#declare variables

variable "aws_access_key" {
  type    = string
  default = "${env("AWS_ACCESS_KEY_ID")}"
}

variable "aws_secret_key" {
  type    = string
  default = "${env("AWS_SECRET_ACCESS_KEY")}"
}

variable "aws_region" {
  type    = string
  default = "${env("AWS_DEFAULT_REGION")}"
}

variable "vpc" {
  type    = string
  default = "vpc-ee3b9594"
}

variable "subnet" {
  type    = string
  default = "subnet-1138155b"
}

variable "azure_client_id" {
  type    = string
  default = "${env("AZURE_CLIENT_ID")}"
}

variable "azure_client_secret" {
  type    = string
  default = "${env("AZURE_CLIENT_SECRET")}"
}

variable "azure_subscription_id" {
  type    = string
  default = "${env("AZURE_SUBSCRIPTION_ID")}"
}

variable "azure_tenant_id" {
  type    = string
  default = "${env("AZURE_TENANT_ID")}"
}

#do a datapull from AWS, below we are finding the latest base image from amazon, a good way to find the
#correct name of the ami to search for is by running a one off aws cli command i.e
#aws ec2 describe-images --image-ids ami-0d1bf5b68307103c2

data "amazon-ami" "linux" {
  filters = {
    name                = "amzn2-ami-hvm-2.*"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["amazon"]
  region      = "${var.aws_region}"
}

#declr a local var, only used in this source block.

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

#configure source AWS AMI

source "amazon-ebs" "linux" {
  ami_name          = "test-ami-${local.timestamp}"
  ami_users         = [273539952517]
  communicator      = "ssh"
  instance_type     = "t2.micro"
  region            = "${var.aws_region}"
  source_ami        = "${data.amazon-ami.linux.id}"
  ssh_username      = "ec2-user"
  subnet_id         = var.subnet
  vpc_id            = var.vpc
  tags = {
      Created-by = "Packer"
      Name = "Gold Image Test"
  }
}

#configure source Azure Image

source "azure-arm" "ubuntu" {
  client_id                         = "${var.azure_client_id}"
  client_secret                     = "${var.azure_client_secret}"
  managed_image_resource_group_name = "packer_images"
  managed_image_name                = "packer-ubuntu-azure-{{timestamp}}"
  subscription_id                   = "${var.azure_subscription_id}"
  tenant_id                         = "${var.azure_tenant_id}"

  os_type         = "Linux"
  image_publisher = "Canonical"
  image_offer     = "UbuntuServer"
  image_sku       = "16.04-LTS"

  azure_tags = {
    Created-by = "Packer"
    OS_Version = "Ubuntu 16.04"
    Release    = "Latest"
    Name = "Gold Image Test"
}

  location = "East US"
  vm_size  = "Standard_A2"
}

#use the same build block, as EXACTLY the same build is required on both the Azure and AWS images

build {
  sources = ["source.amazon-ebs.linux", "source.azure-arm.ubuntu",]

  provisioner "shell" {
    only = ["amazon-ebs.linux"]
    inline = ["sudo amazon-linux-extras install ansible2"]
  }

  provisioner "shell" {
    only = ["azure-arm.ubuntu"]
    inline = ["sudo apt update, sudo apt install software-properties-common, sudo add-apt-repository --yes --update ppa:ansible/ansible, sudo apt install ansible -y"]
  }

  provisioner "ansible-local" {
    playbook_file   = "./ansible/httpd.yaml"
  }
}