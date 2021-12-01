provider "aws" {
  region     = "ap-south-1"
  profile    = "umakey"
}

resource "aws_security_group" "allow" {
  name        = "security_grp1"
  description = "Allow TLS inbound traffic"
  vpc_id      = "vpc-2efd1b45"

  ingress = [
    {
      description      = "ssh"
      from_port        = 0
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    },
    {
      description      = "http"
      from_port        = 0
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }
  ]

  egress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
    }
  ]

  tags = {
    Name = "security_grp1"
  }
}


resource "aws_instance" "web" {
  ami                  = "ami-0447a12f28fddb066"
  instance_type  = "t2.micro"
  key_name        = "mykey123"
  vpc_security_group_ids =  [  aws_security_group.allow.id  ]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.this.private_key_pem
    host     = aws_instance.web.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }

  tags = {
    Name = "ec2-instance1"
  }
}

resource "aws_ebs_volume" "esb1" {
  availability_zone = aws_instance.web.availability_zone
  size              = 1
  tags = {
    Name = "new_ebs"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   =  aws_ebs_volume.esb1.id
  instance_id =  aws_instance.web.id
  force_detach = true
}

resource "null_resource" "nullremote3"  {
depends_on = [
    aws_volume_attachment.ebs_att,
  ]
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.this.private_key_pem
    host     = aws_instance.web.public_ip
  }

provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/umaravuri/cloud-project /var/www/html/"
    ]
  }
}


resource "aws_s3_bucket" "b" {
  bucket = "umaravuri123"
  acl    = "public-read"
  force_destroy = true
}

resource "aws_s3_bucket" "mybucket" {
  bucket   = "my-tf-test-bucketing"
  acl        =  "public-read"

  tags = {
    Name = "My buckettask1"
    Environment = "Deb"
  }
}
resouce "null_resource" "cloning" {
depends_on=[aws_s3_bucket]
 provisioner ="local-exec" {
   command = "git clone https://github.com/umaravuri/cloud-project.git myimage"
  }
}

 resource "aws_s3_bucket_object" "web-object1"{
   bucket = aws_s3_bucket.mybucket.bucket
   key = "hybrid.jpg"
   source = "myimage/hybrid.jpg"
   acl = "public-read"
   depends_on= [aws_s3_bucket.mybucket,null_resource.cloning] 
 }

locals {
  s3_origin_id = "myS3Origin"
}

resource "aws_cloudfront_distribution" "cld_front" {
  origin {
    domain_name =  aws_s3_bucket.b.bucket_domain_name
    origin_id   = local.s3_origin_id
   
    custom_origin_config {
      http_port                            =  80
      https_port                          =  443
      origin_protocol_policy        =  "match-viewer"
      origin_ssl_protocols           =   [ "TLSv1","TLSv1.1","TLSv1.2" ]
    }
  }
  
  enabled  =  true
  is_ipv6_enabled     = true

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id =  local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
  
  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "IN", "GB", "DE"]
    }
  }
} 

resource "null_resource" "nullremote4"  {
depends_on = [
    aws_cloudfront_distribution.cld_front,
  ]
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.this.private_key_pem
    host     = aws_instance.web.public_ip
  }

provisioner "remote-exec" {
    inline = [
      "sudo su <<END",
       "sudo su - root",
      " echo -n  ${aws_cloudfront_distribution.cld_front.domain_name}  > /var/www/html/domain_name.txt ",
     "END"
    ]
  }
}

output "myos_ip" {
  value = aws_instance.web.public_ip
}

output "domain_name" {
     value =  aws_cloudfront_distribution.cld_front.domain_name
}