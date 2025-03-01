data "oci_core_instance" "langley_instance" {
  compartment_id = var.compartment_id
  display_name   = "langley-web-instance"  # Ensure this is the correct instance name
}

resource "oci_load_balancer" "web_lb" {
  count    = var.region == "us-luke-1" ? 1 : 0  ## West
  compartment_id = var.compartment_id
  display_name   = "web-load-balancer"
  shape         = var.lb_shape
  subnet_ids    = [var.subnet_id]
}

resource "oci_load_balancer_backend_set" "web_backend_set" {
  count    = var.region == "us-luke-1" ? 1 : 0  ## West
  name             = "web-backend-set"
  load_balancer_id = oci_load_balancer.web_lb.id
  policy           = "ROUND_ROBIN"

  health_checker {
    protocol    = "HTTP"
    port        = 80
    interval_ms = 10000
    timeout_in_millis = 3000
    retries     = 3
    return_code = 200
    url_path    = "/"
  }
}

# Use Dynamic Backend IPs from VM Instances
resource "oci_load_balancer_backend" "backend_luke" {
  load_balancer_id = oci_load_balancer.web_lb.id
  backend_set_name = oci_load_balancer_backend_set.web_backend_set.name
  ip_address       = oci_core_instance.luke_instance.private_ip
  port             = 80
  weight           = 1
}

resource "oci_load_balancer_backend" "backend_langley" {
  load_balancer_id = oci_load_balancer.web_lb.id
  backend_set_name = oci_load_balancer_backend_set.web_backend_set.name
  ip_address       = oci_core_instance.langley_instance.private_ip
  port             = 80
  weight           = 1
}

resource "oci_load_balancer_listener" "web_listener" {
  load_balancer_id        = oci_load_balancer.web_lb.id
  name                    = "web-listener"
  default_backend_set_name = oci_load_balancer_backend_set.web_backend_set.name
  port                    = 80
  protocol                = "HTTP"
}
