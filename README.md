# Packer-AWS-Azure

Repo for the use of Packer and Ansible to create simple "gold" VM images in AWS and Azure.

- Packer creates a gold image in both AWS and Azure using the respective marketplace images as a base
  - Amazon Linux 2 in AWS
  - Ubuntu 18.04 in Azure
- The packer build block uses a provisioner to install Ansible with an "only" statement to run differnt commands dependent on O/S
- Ansible installs Apache and configures a basic default website on each image. Ansible uses a "when" statement to run differnt commands dependent on O/S
- The gold images can be used in EC2 Auto Scaling Groups or Azure VM Scale Sets to create a horizontally scaled web farm
