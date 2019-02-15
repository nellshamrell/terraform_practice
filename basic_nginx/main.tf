provider "aws" {
    region = "us-east-1"
}

data "template_file" "index_html" {
    template = "${file("index_html.tpl")}"

    vars {
        hello_message = "${var.hello_message}"
    }
}

resource "aws_security_group" "base_sg" {
    name = "base_sg"
    description = "allow ssh, http, https traffic"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "base" {
    ami = "ami-0ac019f4fcb7cb7e6"
    instance_type = "t2.micro"
    key_name = "${var.key_name}"
    security_groups = [
      "${aws_security_group.base_sg.name}"
    ]

    provisioner "file" {
        content = "${data.template_file.index_html.rendered}"
        destination = "/tmp/index.html"

        connection {
            host = "${self.public_ip}"
            type = "ssh"
            user = "ubuntu"
            private_key = "${file("${var.private_key_path}")}"
        }
    }

    provisioner "remote-exec" {
        inline = [
            "sudo apt-get update",
            "sleep 120",
            "sudo apt-get -y install nginx",
            "sudo mv /tmp/index.html /var/www/html/"
        ]

        connection {
            host = "${self.public_ip}"
            type = "ssh"
            user = "ubuntu"
            private_key = "${file("${var.private_key_path}")}"
        }
    }
}

output "base_ip" {
    value = "${aws_instance.base.public_ip}"
}