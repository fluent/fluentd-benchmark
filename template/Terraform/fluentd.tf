provider "google" {
  credentials = "${file("credential.json")}"
  project = "fluentd-benchmark"
  region = "asia-norhteast1"
}

# resource "google_compute_network" "fluentd-benchmark" {
#   name = "fluentd-benchmark"
# }

# resource "google_compute_subnetwork" "benchmark" {
#   name = "benchmark"
#   ip_cidr_range = "10.30.0.0/16"
#   network = "${google_compute_network.fluentd-benchmark.name}"
#   description = "Fluentd benchmark"
#   region = "asia-northeast1"
# }

# resource "google_compute_firewall" "benchmark" {
#   name = "benchmark"
#   network = "${google_compute_network.fluentd-benchmark.name}"

#   allow {
#     protocol = "icmp"
#   }

#   allow {
#     protocol = "tcp"
#     ports    = ["22", "80", "443", "8086", "3000"]
#   }

#   target_tags = ["benchamrk"]
# }

resource "google_compute_instance" "server" {
  name = "server"
  machine_type = "n1-standard-2"
  zone = "asia-northeast1-a"
  tags = ["benchmark"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
      type = "pd-standard"
      size = 10
    }
  }

  network_interface = {
    network = "default"
    access_config {
    }

    #subnetwork = "${google_compute_subnetwork.benchmark.name}"
  }

  scheduling {
    preemptible = false
  }
}

resource "google_compute_instance" "kafka" {
  name = "kafka"
  machine_type = "n1-standard-2"
  zone = "asia-northeast1-a"
  tags = ["benchmark"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
      type = "pd-standard"
      size = 10
    }
  }

  network_interface = {
    network = "default"
    access_config {
    }

    #subnetwork = "${google_compute_subnetwork.benchmark.name}"
  }

  scheduling {
    preemptible = false
  }
}

resource "google_compute_instance" "metrics" {
  name = "metrics"
  machine_type = "n1-standard-2"
  zone = "asia-northeast1-a"
  tags = ["benchmark"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
      type = "pd-standard"
      size = 10
    }
  }

  network_interface = {
    network = "default"
    access_config {
    }
    #subnetwork = "${google_compute_subnetwork.benchmark.name}"
  }

  scheduling {
    preemptible = false
  }
}

resource "google_compute_instance" "client1" {
  name = "client1"
  machine_type = "n1-standard-2"
  zone = "asia-northeast1-a"
  tags = ["benchmark"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
      type = "pd-standard"
      size = 10
    }
  }

  network_interface = {
    network = "default"
    access_config {
    }
    #subnetwork = "${google_compute_subnetwork.benchmark.name}"
  }

  scheduling {
    preemptible = false
  }
}

output "ip" {
  value = {
    "${google_compute_instance.server.name}" = [
      "${google_compute_instance.server.network_interface.0.access_config.0.assigned_nat_ip}",
      "${google_compute_instance.server.network_interface.0.address}",
    ],
    "${google_compute_instance.metrics.name}" = [
      "${google_compute_instance.metrics.network_interface.0.access_config.0.assigned_nat_ip}",
      "${google_compute_instance.metrics.network_interface.0.address}",
    ],
    "${google_compute_instance.kafka.name}" = [
      "${google_compute_instance.kafka.network_interface.0.access_config.0.assigned_nat_ip}",
      "${google_compute_instance.kafka.network_interface.0.address}",
    ],
    "${google_compute_instance.client1.name}" = [
      "${google_compute_instance.client1.network_interface.0.access_config.0.assigned_nat_ip}",
      "${google_compute_instance.client1.network_interface.0.address}",
    ],
  }
}

