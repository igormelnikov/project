provider "google" {
  version = "1.19.1"
  project = "${var.project}"
  region  = "${var.region}"
}

resource "google_compute_project_metadata_item" "ssh-users" {
  key   = "ssh-keys"
  value = "appuser:${file(var.public_key_path)}"
}

resource "google_compute_instance" "gitlab-host" {
  name         = "gitlab-host"
  machine_type = "n1-standard-1"
  zone = "${var.zone}"
  tags = ["http-server", "https-server", "docker-registry"]
  labels = {
    "gitlab" = ""
  }
  boot_disk {
    initialize_params {
      image = "ubuntu-1604-lts"
      size = 100
    }
  }
  network_interface {
    network = "default"
    access_config = {
    }
  }
}

resource "google_compute_firewall" "firewall_http" {
  name    = "default-allow-http"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  target_tags   = ["http-server"]
}

resource "google_compute_firewall" "firewall_https" {
  name    = "default-allow-https"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
  target_tags   = ["https-server"]
}

resource "google_compute_firewall" "firewall_ui" {
  name = "allow-search-engine-ui"
  network = "default"
  allow {
    protocol = "tcp"
    ports = ["8000"]
  }
  target_tags = ["docker-machine"]
}

resource "google_compute_firewall" "firewall_registry" {
  name = "allow-registry"
  network = "default"
  allow {
    protocol = "tcp"
    ports = ["4567"]
  }
  target_tags = ["docker-registry"]
}

resource "google_compute_firewall" "firewall_cadvisor" {
  name = "allow-cadvisor"
  network = "default"
  allow {
    protocol = "tcp"
    ports = ["8080"]
  }
  target_tags = ["docker-machine"]
}

resource "google_compute_firewall" "firewall_prometheus" {
  name = "allow-prometheus"
  network = "default"
  allow {
    protocol = "tcp"
    ports = ["9090"]
  }
  target_tags = ["docker-machine"]
}

resource "google_compute_firewall" "firewall_grafana" {
  name = "allow-grafana"
  network = "default"
  allow {
    protocol = "tcp"
    ports = ["3000"]
  }
  target_tags = ["docker-machine"]
}

resource "google_compute_firewall" "firewall_alertmanager" {
  name = "allow-alertmanager"
  network = "default"
  allow {
    protocol = "tcp"
    ports = ["9093"]
  }
  target_tags = ["docker-machine"]
}

module "storage-bucket" {
  source  = "SweetOps/storage-bucket/google"
  version = "0.1.1"
  name    = ["gitlab-state"]
}


output "host_external_ip" {
  value = "${google_compute_instance.gitlab-host.network_interface.0.access_config.0.assigned_nat_ip}"
}
