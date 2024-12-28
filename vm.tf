/**
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


resource "google_compute_health_check" "iap-http-health-check" {
  project = local.project_id
  name    = "iap-http-health-check"

  timeout_sec        = 5
  check_interval_sec = 5

  tcp_health_check {
    port = "80"
  }
}


resource "google_compute_instance_template" "iap_instance_template" {
  project = local.project_id
  name    = "iap-instance-template"
  region  = local.project_default_region

  machine_type = "e2-medium"

  network_interface {
    subnetwork = google_compute_subnetwork.custom-subnet.id
    stack_type = "IPV4_ONLY"

    access_config {
      // Ephemeral public IP
    }
  }

  disk {
    auto_delete  = true
    boot         = true
    disk_size_gb = 10
    disk_type    = "pd-balanced"
    type         = "PERSISTENT"
    source_image = "projects/debian-cloud/global/images/debian-12-bookworm-v20241210"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  metadata = {
    startup-script = <<-EOT
#!/bin/bash
apt update
apt -y install apache2
echo "Hello world from $(hostname) $(hostname -i)" > /var/www/html/index.html
    EOT
  }

  tags = ["http-server"]

  reservation_affinity {
    type = "ANY_RESERVATION"
  }


}


resource "google_compute_region_instance_group_manager" "iap-instance-group" {

  project = local.project_id
  name    = "iap-instance-group"

  base_instance_name        = "iap-instance-group"
  region                    = local.project_default_region
  distribution_policy_zones = data.google_compute_zones.available.names

  target_size = 2

  version {
    instance_template = google_compute_instance_template.iap_instance_template.self_link_unique
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.iap-http-health-check.id
    initial_delay_sec = 30
  }

  named_port {
    name = "http"
    port = 80
  }
}


resource "google_compute_backend_service" "iap-instance-backend-srv" {
  depends_on = [google_compute_region_instance_group_manager.iap-instance-group,
    google_compute_instance_template.iap_instance_template
  ]

  project = var.project_id
  name    = "iap-instance-backend-srv"

  port_name                   = "http"
  protocol                    = "HTTP"
  timeout_sec                 = 30
  ip_address_selection_policy = "IPV4_ONLY"
  locality_lb_policy          = "ROUND_ROBIN"
  load_balancing_scheme       = "EXTERNAL_MANAGED"

  health_checks = [google_compute_health_check.iap-http-health-check.self_link]

  backend {
    balancing_mode               = "UTILIZATION"
    capacity_scaler              = 1
    group                        = "https://www.googleapis.com/compute/v1/projects/${local.project_id}/regions/${local.project_default_region}/instanceGroups/iap-instance-group"
    max_connections              = 0
    max_connections_per_endpoint = 0
    max_connections_per_instance = 0
    max_rate                     = 0
    max_rate_per_endpoint        = 0
    max_rate_per_instance        = 0
    max_utilization              = 0.8

  }
}


