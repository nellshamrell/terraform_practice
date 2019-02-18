provider "aws" {
    region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true 
}

resource "aws_subnet" "public-subnet" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"

    tags {
        Name = "Public Subnet"
    }
}

resource "aws_subnet" "private-subnet" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "10.0.2.0/24"
    availability_zone = "us-east-1b"

    tags {
        Name = "Private Subnet"
    }
}

resource "aws_internet_gateway" "gw" {
    vpc_id = "${aws_vpc.main.id}"

    tags = {
        Name = "AWS VPC IGW"
    }
}

resource "aws_route_table" "web-public-rt" {
    vpc_id = "${aws_vpc.main.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.gw.id}"
    }

    tags {
        Name = "Public Subnet RT"
    }
}

resource "aws_route_table_association" "web-public-rt" {
    subnet_id = "${aws_subnet.public-subnet.id}"
    route_table_id = "${aws_route_table.web-public-rt.id}"
}

resource "aws_security_group" "sgweb" {
    name = "vpc_test_web"
    description = "Allow incoming HTTP connections and SSH access"
    vpc_id = "${aws_vpc.main.id}"

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

data "template_file" "index_html" {
    template = "${file("index_html.tpl")}"

    vars {
        hello_message = "${var.hello_message}"
    }
}

resource "aws_instance" "web" {
    instance_type = "t2.micro"
    ami = "ami-0ac019f4fcb7cb7e6"
    key_name = "${var.key_name}"
    subnet_id = "${aws_subnet.public-subnet.id}"
    vpc_security_group_ids = ["${aws_security_group.sgweb.id}"]
    associate_public_ip_address = true

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

output "aws_vpc_id" {
    value = "${aws_vpc.main.id}"
}

output "web_instance_public_ip" {
    value = "${aws_instance.web.public_ip}"
}
