resource "google_compute_global_address" "entrypoint" {
  name = "entrypoint"
}

resource "google_compute_global_forwarding_rule" "default" {
  name = "entrypoint"
  ip_address = "${google_compute_global_address.entrypoint.address}"
  port_range = "443"
  target = "${google_compute_target_https_proxy.default.self_link}"
}

resource "google_compute_target_https_proxy" "default" {
  name    = "default-target-proxy"
  url_map = "${google_compute_url_map.default.self_link}"
  ssl_certificates = ["${google_compute_ssl_certificate.default.self_link}"]
}

resource "google_compute_ssl_certificate" "default" {
  name = "letsencrypt-imel-project-ml"
  private_key = "${file("imel-project.ml.key")}"
  certificate = "${file("imel-project.ml.crt")}"
}

resource "google_compute_url_map" "default" {
  name            = "default"
  default_service = "${google_compute_backend_service.gitlab.self_link}"
}

resource "google_compute_backend_service" "gitlab" {
  name      = "gitlab"
  port_name = "https"
  protocol  = "HTTPS"

  backend {
    group = "${google_compute_instance_group.gitlab.self_link}"
  }

  health_checks = ["${google_compute_https_health_check.gitlab.self_link}"]
}

resource "google_compute_instance_group" "gitlab" {
  name = "gitlab"
  
  instances = ["${google_compute_instance.gitlab-host.self_link}"]

  named_port {
    name = "https"
    port = 443
  }

  named_port {
    name = "registry"
    port = 4567
  }
}

resource "google_compute_https_health_check" "gitlab" {
  name         = "gitlab-check"
  request_path = "/-/health"
}

resource "google_compute_global_forwarding_rule" "registry" {
  name = "registry"
  ip_address = "${google_compute_global_address.entrypoint.address}"
  port_range = "25"
  target = "${google_compute_target_ssl_proxy.registry.self_link}"
}

resource "google_compute_target_ssl_proxy" "registry" {
  name    = "registry-proxy"
  ssl_certificates = ["${google_compute_ssl_certificate.default.self_link}"]
  backend_service = "${google_compute_backend_service.registry.self_link}"
}

resource "google_compute_backend_service" "registry" {
  name      = "gitlab-registry"
  port_name = "registry"
  protocol  = "SSL"

  backend {
    group = "${google_compute_instance_group.gitlab.self_link}"
  }

  health_checks = ["${google_compute_health_check.registry.self_link}"]
}

resource "google_compute_health_check" "registry" {
  name = "registry-health-check"
  ssl_health_check {
    port = "4567"
  }
}
