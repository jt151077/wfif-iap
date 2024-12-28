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


data "google_compute_zones" "available" {
  project = local.project_id
  region  = local.project_default_region
}

resource "google_compute_network" "custom_vpc" {
  depends_on = [
    google_project_service.gcp_services
  ]

  name                    = "custom-vpc"
  project                 = local.project_id
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "custom-subnet" {
  depends_on = [
    google_project_service.gcp_services,
    google_compute_network.custom_vpc
  ]

  name          = "subnet-${local.project_default_region}"
  project       = local.project_id
  ip_cidr_range = "10.51.0.0/20"
  region        = local.project_default_region
  network       = google_compute_network.custom_vpc.id
}
/*
resource "google_compute_firewall" "allow-http" {
  depends_on = [
    google_project_service.gcp_services,
    google_compute_network.custom_vpc
  ]

  name      = "http-allowed"
  project   = local.project_id
  direction = "INGRESS"
  network   = google_compute_network.custom_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
}
*/
resource "google_compute_firewall" "allow-iap-traffic" {
  depends_on = [
    google_project_service.gcp_services,
    google_compute_network.custom_vpc
  ]

  name      = "allow-iap-traffic"
  project   = local.project_id
  direction = "INGRESS"
  network   = google_compute_network.custom_vpc.id

  allow {
    protocol = "tcp"
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16", "35.235.240.0/20"]
}

# LB with https (http redirect to https)
resource "google_compute_target_http_proxy" "default" {
  depends_on = [
    google_project_service.gcp_services
  ]

  project = var.project_id
  name    = "${var.project_id}-http-proxy"
  url_map = google_compute_url_map.https_redirect.self_link
}

resource "google_compute_target_https_proxy" "default" {
  depends_on = [
    google_project_service.gcp_services
  ]

  project = var.project_id
  name    = "${var.project_id}-https-proxy"
  url_map = google_compute_url_map.default.self_link

  ssl_certificates = [
    google_compute_managed_ssl_certificate.default.self_link
  ]
}

resource "google_compute_managed_ssl_certificate" "default" {
  project = var.project_id
  name    = "${var.project_id}-cert"

  lifecycle {
    create_before_destroy = true
  }

  managed {
    domains = [var.domain]
  }
}

resource "google_compute_url_map" "default" {
  depends_on = [
    google_compute_backend_service.iap-instance-backend-srv
  ]

  project         = var.project_id
  name            = "${var.project_id}-url-map"
  default_service = google_compute_backend_service.iap-instance-backend-srv.self_link
}


resource "google_compute_url_map" "https_redirect" {
  project = var.project_id
  name    = "${var.project_id}-https-redirect"

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_global_forwarding_rule" "http" {
  project               = var.project_id
  name                  = "${var.project_id}-http"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  target                = google_compute_target_http_proxy.default.self_link
  ip_address            = google_compute_global_address.default.address
  port_range            = "80"
}


resource "google_compute_global_forwarding_rule" "https" {
  project               = var.project_id
  name                  = "${var.project_id}-https"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  target                = google_compute_target_https_proxy.default.self_link
  ip_address            = google_compute_global_address.default.address
  port_range            = "443"
}

resource "google_compute_global_address" "default" {
  project    = var.project_id
  name       = "${var.project_id}-address"
  ip_version = "IPV4"
}


resource "google_iap_brand" "project_brand" {
  support_email     = var.iap_brand_support_email
  application_title = "Cloud IAP protected Application"
  project           = var.project_nmr
}


resource "google_iap_web_backend_service_iam_binding" "iap-backend-binding" {
  depends_on = [
    google_compute_backend_service.iap-instance-backend-srv
  ]
  project             = var.project_id
  web_backend_service = google_compute_backend_service.iap-instance-backend-srv.name
  role                = "roles/iap.httpsResourceAccessor"
  members = [
    "principalSet://iam.googleapis.com/${google_iam_workforce_pool.wfif-pool.id}/*",
  ]
}


output "lb_external_ip" {
  value = google_compute_global_address.default.address
}


