terraform {
  backend "gcs" {
    bucket = "gitlab-state"
  }
}


provider "google" {
  version = "1.19.1"
  credentials = "${file("~/gcloud-service-key.json")}"
  project = "${var.project}"
  region  = "${var.region}"
  zone = "${var.zone}"
}

resource "google_compute_instance" "machine" {
  name         = "${var.env_name}"
  allow_stopping_for_update = true
  machine_type = "n1-standard-1"
  tags = ["http-server", "https-server", "docker-machine"]
  boot_disk {
    initialize_params {
      image = "ubuntu-1604-lts"
    }
  }
  network_interface {
    network = "default"
    access_config = {
    }
  }
}

resource "google_compute_instance_group" "group" {
  name = "${var.env_name}"
  
  instances = ["${google_compute_instance.machine.self_link}"]

  named_port {
    name = "ui"
    port = 8000
  }
}

output "external_ip" {
  value = "${google_compute_instance.machine.network_interface.0.access_config.0.nat_ip}"
}

output "internal_ip" {
  value = "${google_compute_instance.machine.network_interface.0.network_ip}"
}

