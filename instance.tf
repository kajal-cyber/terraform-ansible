resource "aws_instance" "ansible-master" { #public instances
  ami                    = "ami-08e5424edfe926b43"
  subnet_id              = aws_subnet.Terraform_public_subnet.id
  key_name               = "Demo_ans_key"
  vpc_security_group_ids = [aws_security_group.Terraform_public_SG.id]
  iam_instance_profile   = aws_iam_instance_profile.SSMRoleforEC2_profile.id
  instance_type          = "t2.micro"
  tags = {
    Name = "Ansible-master"
  }

  #--------Provisioner---------------------installing ansible on master node
  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt install software-properties-common -y",
      "sudo add-apt-repository --yes --update ppa:ansible/ansible",
      "sudo apt install ansible -y",
      "echo '[servers]' > hosts",

    ]
    on_failure = fail
  }
  #-------------------------------------------------------for passwordless SSH

  provisioner "file" {
    source      = "/var/tmp/Demo_ans_key.pem"
    destination = "/home/ubuntu/.ssh/Demo_ans_key.pem"
    on_failure  = fail

  }
  #-----------------------------push yml file to master node-----------------
  provisioner "file" {
    source      = "./nginx.yml"
    destination = "/home/ubuntu/nginx.yml"
    on_failure  = fail

  }
  #-----------------------------------part of passwordless ssh----------------------------
  provisioner "remote-exec" {
    inline = [
      "cd ~/.ssh",
      "sudo chmod 600 *.pem",
      "echo 'Host *\n\tStrictHostKeyChecking no\n\tUser ubuntu\n\tIdentityFile /home/ubuntu/.ssh/Demo_ans_key.pem' > config",
    ]
    on_failure = fail
  }
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = "/var/tmp/Demo_ans_key.pem"
    # host        = aws_instance.terraform_instance[0].public_ip
    host = self.public_ip

  }
}
#-----------------------------------------------------------------------Ansible host nodes


resource "aws_instance" "ansible-hosts" { #public instances
  ami                    = "ami-08e5424edfe926b43"
  subnet_id              = aws_subnet.Terraform_public_subnet.id
  key_name               = "Demo_ans_key"
  vpc_security_group_ids = [aws_security_group.Terraform_public_SG.id]
  iam_instance_profile   = aws_iam_instance_profile.SSMRoleforEC2_profile.id
  instance_type          = "t2.micro"
  count                  = 2

  tags = {
    Name = "Ansible-host-${count.index}"
  }

}

#-------------------------------------------------inventory file

# resource "null_resource" "inventory" {
#   count = 2
#   depends_on = [aws_instance.ansible-hosts]
#   # command = "echo ${element(aws_instance.myInstanceAWS.*.public_ip, count.index)} >> hosts"

#   provisioner "local-exec" {

#     command = "echo ${element(aws_instance.ansible-hosts[*].tags["Name"], count.index)} ansible_host=${element(aws_instance.ansible-hosts.*.public_ip, count.index)} ansible_connection=ssh ansible_user=ubuntu >> hosts"

#   }

# }
# resource "null_resource" "transfer_inventorytohostnode" {
#   depends_on = [null_resource.inventory]
#   provisioner "file" {
#     source      = "hosts"
#     destination = "/home/ubuntu/inventory.txt"
#     on_failure  = fail

#     connection {
#       type        = "ssh"
#       user        = "ubuntu"
#       private_key = file("Demo_ans_key.pem")
#       # host        = aws_instance.terraform_instance[0].public_ip
#       host = aws_instance.ansible-master.public_ip

#     }

#   }
# }



#-----------------inventory on master node------------------------------

resource "null_resource" "remoteexec-for-inventoryfile" {
  count      = 2
  depends_on = [aws_instance.ansible-hosts, aws_instance.ansible-master]
  provisioner "remote-exec" {
    on_failure = fail
    inline = [
      # "echo '[servers]' > hosts",
      "echo ${element(aws_instance.ansible-hosts[*].tags["Name"], count.index)} ansible_host=${element(aws_instance.ansible-hosts.*.public_ip, count.index)} ansible_connection=ssh ansible_user=ubuntu >> hosts"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "/var/tmp/Demo_ans_key.pem"
      # host        = aws_instance.terraform_instance[0].public_ip
      host = aws_instance.ansible-master.public_ip

    }
  }
}

#-------------------provisioner for ping / run nginx--------------------------

resource "null_resource" "ping" {
  depends_on = [null_resource.remoteexec-for-inventoryfile]
  provisioner "remote-exec" {
    on_failure = fail
    inline = [

      "ansible servers -m ping -i hosts",
      "ansible-playbook nginx.yml -v -i hosts"

    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "/var/tmp/Demo_ans_key.pem"
      # host        = aws_instance.terraform_instance[0].public_ip
      host = aws_instance.ansible-master.public_ip

    }

  }
}
