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

locals {
  project_id              = var.project_id
  project_number          = var.project_nmr
  project_default_region  = var.project_default_region
  iap_brand_support_email = var.iap_brand_support_email
  organization_nmr        = var.organization_nmr
  oidc_client_id          = var.oidc_client_id
  oidc_client_secret      = var.oidc_client_secret

  gcp_service_list = [
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "iap.googleapis.com",
    "storage.googleapis.com"
  ]
}

resource "google_project_service" "gcp_services" {
  project            = local.project_id
  for_each           = toset(local.gcp_service_list)
  service            = each.key
  disable_on_destroy = false
}


terraform {
  required_version = ">= 1.9.8"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.13.0"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 6.13.0"
    }
  }
}
