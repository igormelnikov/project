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
}

resource "google_compute_https_health_check" "gitlab" {
  name         = "gitlab-check"
  request_path = "/-/health"
}
