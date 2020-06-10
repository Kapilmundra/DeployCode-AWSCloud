provider "aws" {
  region     = "ap-south-1"
  profile    = "kapil"
}


#Genetrating key
resource "aws_key_pair" "deployer" {
  key_name   = "kapil-deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAoBrQ3+wXuzVBuecVGZAtvZHkCi/wADYpgd2jm5HNiSSPGBcNv/f6TEwOavTVZAjxoneTgc7+YrS3Dtf6zCLooKvu0dDpgHzvfqQnOLF9ChwSuPWJKm/TKnTPwHhJN6kHdD9Q0w5k+bIvewiQuxVRvsp7JewtVJFABt2HYC8dpRssKPNgW02LJhoMenlO4AbMgLdWh95yLCIDCk3SzXvnEm7T0H7vyi6e2ZMrwZHWDDb/n4MavKsNAoRcfQHDS+ecprOy+azL45vTbQKpw9ymrUfivKX24SnsHxRzLJjHidOh6xf6XIRk0XJBPcLUxni+YjvjIPGRWhr4e+8uTqbH1Q=="
}


#Security group
resource "aws_security_group" "security_permission" {
  name        = "security_permission"
  description = "Allow SSH and HTTP inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "security_permission"
  }
}


#Launch a ec2 instance
resource "aws_instance" "linuxworld" {
  ami           = "ami-07a8c73a650069cf3"
  instance_type = "t2.micro"
  key_name      = "kapil-deployer-key"
  security_groups = [ "security_permission" ]

  tags = {
    Name = "LinuxWorld"
  }
}


#Launch one volume ebs
resource "aws_ebs_volume" "ebs_vol" {
  availability_zone = "ap-south-1b"
  size              = 1

  tags = {
    Name = "ebs_vol"
  }
}

#Attach ebs_vol to ec2_instance
resource "aws_volume_attachment" "ebs_attach" {
  device_name = "/dev/sda2"
  volume_id   = "vol-0150ceb86d98a348d"
  instance_id = "i-0b21db2ac58d7aae5"
}


resource "aws_s3_bucket" "github-image-upload" {
  bucket = "github-images-upload"
  acl    = "public-read"

  tags = {
    Name  = "github-images-upload"
  }
}


# Create Cloudfront distribution
resource "aws_cloudfront_distribution" "prod_distribution1305" {
    origin {
        domain_name = "github-images-upload.s3.amazonaws.com"
        origin_id = "S3-github-images-upload" 

        custom_origin_config {
            http_port = 80
            https_port = 80
            origin_protocol_policy = "match-viewer"
            origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"] 
        }
    }
       
    enabled = true

    default_cache_behavior {
        allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods = ["GET", "HEAD"]
        target_origin_id = "S3-github-images-upload"

        # Forward all query strings, cookies and headers
        forwarded_values {
            query_string = false
        
            cookies {
               forward = "none"
            }
        }
        viewer_protocol_policy = "allow-all"
        min_ttl = 0
        default_ttl = 3600
        max_ttl = 86400
    }



    # Restricts who is able to access this content
    restrictions {
        geo_restriction {
            # type of restriction, blacklist, whitelist or none
            restriction_type = "none"
        }
    }

    # SSL certificate for the service.
    viewer_certificate {
        cloudfront_default_certificate = true
    }
}












