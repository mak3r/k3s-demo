resource "aws_elb" "k3s-multi" {
  name               = "${var.prefix}-k3s-multi"
  availability_zones = aws_instance.opensuse_vms[*].availability_zone

  listener {
    instance_port     = 80
    instance_protocol = "tcp"
    lb_port           = 80
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 443
    instance_protocol = "tcp"
    lb_port           = 443
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 6443
    instance_protocol = "tcp"
    lb_port           = 6443
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:80"
    interval            = 30
  }

  instances                   = [
    aws_instance.opensuse_vms[1].id,
    aws_instance.opensuse_vms[2].id,
    aws_instance.opensuse_vms[3].id
  ]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "${var.prefix}-k3s-multi"
  }
}

resource "aws_route53_record" "k3s-multi" {
  zone_id = data.aws_route53_zone.rancher.zone_id
  name    = "k3s-multi.${data.aws_route53_zone.rancher.name}"
  type    = "CNAME"
  ttl     = "5"

  records        = ["${aws_elb.k3s-multi.dns_name}."]
}