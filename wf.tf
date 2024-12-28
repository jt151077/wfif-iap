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


resource "random_string" "random_suffix" {
  length  = 8
  special = false
  upper   = false
}


resource "google_iam_workforce_pool" "wfif-pool" {
  display_name      = "${random_string.random_suffix.result}-wfif-pool"
  workforce_pool_id = "${random_string.random_suffix.result}-wfif-pool"
  parent            = "organizations/${local.organization_nmr}"
  location          = "global"
}

resource "google_iam_workforce_pool_provider" "oidc-provider" {
  workforce_pool_id = google_iam_workforce_pool.wfif-pool.workforce_pool_id
  location          = google_iam_workforce_pool.wfif-pool.location
  provider_id       = "${random_string.random_suffix.result}-oidc-provider"
  display_name      = "${random_string.random_suffix.result}-oidc-provider"

  attribute_mapping = {
    "google.subject"      = "assertion.sub"
    "google.display_name" = "assertion.preferred_username"
    "google.groups"       = "assertion.groups"
  }

  oidc {
    issuer_uri = local.issuer_uri
    client_id  = local.oidc_client_id

    client_secret {
      value {
        plain_text = local.oidc_client_secret
      }
    }

    web_sso_config {
      response_type             = "CODE"
      assertion_claims_behavior = "MERGE_USER_INFO_OVER_ID_TOKEN_CLAIMS"
    }
  }
}

output "workforce_pool_id" {
  value = google_iam_workforce_pool.wfif-pool.id
}