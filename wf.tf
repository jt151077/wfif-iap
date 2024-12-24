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

resource "google_iam_workforce_pool" "wfif-test-pool" {
  display_name      = "wfif-test-pool"
  workforce_pool_id = "wfif-test-pool"
  parent            = "organizations/${local.organization_nmr}"
  location          = "global"
}

resource "google_iam_workforce_pool_provider" "azure-ad-oidc-provider" {
  workforce_pool_id = google_iam_workforce_pool.wfif-test-pool.workforce_pool_id
  location          = google_iam_workforce_pool.wfif-test-pool.location
  provider_id       = "azure-ad-oidc-provider"
  display_name      = "azure-ad-oidc-provider"

  attribute_mapping = {
    "google.subject"      = "assertion.sub"
    "google.display_name" = "assertion.preferred_username"
    "google.groups"       = "assertion.groups"
  }

  oidc {
    issuer_uri = "https://login.microsoftonline.com/8048ab41-d5f5-4fc5-8cf3-5f61d491d264/v2.0"
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

