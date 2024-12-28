# VM Instance Group protected by IAP and Workforce Identity Federation





## Setup

1. Find out your GCP project's id and number from the dashboard in the cloud console, and update the following variables in the `terraform.tfvars.json` file. Replace `YOUR_PROJECT_NMR`, `YOUR_PROJECT_ID`, `your_project_region`, `oidc_client_id`, `oidc_client_secret`, `organization_nmr` and `issuer_uri` with the correct values. `YOUR_IAP_SUPPORT_EMAIL` needs be part of your organisation, and which will be the support email for the IAP brand. Create an A record under your Cloud DNS and use this as `YOUR_DOMAIN`, and have it point to the Load Balancer static IP when it is created.

```shell
{
    "project_id": "YOUR_PROJECT_ID",
    "project_nmr": YOUR_PROJECT_NMR,
    "project_default_region": "YOUR_PROJECT_REGION",
    "iap_brand_support_email": "YOUR_IAP_SUPPORT_EMAIL",
    "domain": "YOUR_DOMAIN",
    "organization_nmr": organization_nmr,
    "oidc_client_id": "YOUR_OIDC_CLIENT_ID",
    "oidc_client_secret": "YOUR_OIDC_CLIENT_SECRET",
    "issuer_uri": "YOUR_OIDC_CLIENT_ISSUER_URI"
}
```

## Install

1. Run the following command at the root of the folder:
```shell 
$ sudo ./install.sh
$ terraform init
$ terraform plan
$ terraform apply
```

> Note: You may have to run `terraform plan` and `terraform apply` twice if you get errors for serviceaccounts not found

2. Update the domain so that it points to the `lb_external_ip` address, which is output by terraform. Keep also the value of `workforce_pool_id` from the output for later use.

3. In the console, under Security => Identity-Aware Proxy, enable the IAP on the backend service by clicking on the toggle button. After a few minutes, the status should be "OK" 

4. Open a Cloud Shell on the same project and run the following commands:

```shell
gcloud iam oauth-clients create iap-wfif \
    --project=<YOUR_PROJECT_ID> \
    --location=global \
    --client-type="CONFIDENTIAL_CLIENT" \
    --display-name="iap-wfif" \
    --description="An application registration for iap-wfif" \
    --allowed-scopes="https://www.googleapis.com/auth/cloud-platform" \
    --allowed-redirect-uris="https://127.0.0.1" \
    --allowed-grant-types="authorization_code_grant"


gcloud iam oauth-clients describe iap-wfif \
    --project <YOUR_PROJECT_ID> \
    --location global
```

Copy the `client_id` value from the ouput (ex: clientId: abebf9c59-d6b6-4237-b0aa-9e1505cXXXXX)

5. In the console, under API & Services => Credentials, click on the `IAP-iap-instance-backend-srv`. Replace the Authorized Redirect URI with:

```shell
https://iap.googleapis.com/v1/oauth/clientIds/<PASTE_CLIENT_ID_HERE>:handleRedirect
```

Save the changes.


6. In Cloud Shell on the same project and run the following commands:

```shell
gcloud iam oauth-clients update iap-wfif \
    --project=<YOUR_PROJECT_ID> \
    --location=global \
    --allowed-redirect-uris="https://iap.googleapis.com/v1/oauth/clientIds/<PASTE_CLIENT_ID_HERE>:handleRedirect"


gcloud iam oauth-clients credentials create iap-wfif-secret \
    --oauth-client=iap-wfif \
    --display-name='iap-wfif client credential' \
    --location='global'
```

verify that the secret exists, and print the secret:

```shell
gcloud iam oauth-clients credentials list \
    --oauth-client=iap-wfif \
    --project=<YOUR_PROJECT_ID> \
    --location=global


gcloud iam oauth-clients credentials describe iap-wfif-secret \
    --oauth-client=iap-wfif \
    --location='global'
```

Copy the `clientSecret` value from the ouput (ex: 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e779c19e03cd202f1d27d28bf57df35XXXXX)

6. Update `CLIENT_ID`, `CLIENT_SECRET`, and `WORKFORCE_POOL_NAME` (here use the `workforce_pool_id` you got from the output) in the following command, paste it in Cloud Shell and execute:

```shell
CLIENT_ID=abbfdd3ad-25c7-4939-a621-1c62b94XXXXX
CLIENT_SECRET=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82e3032f19d77f3bb2e026eb887fd94XXXXX
WORKFORCE_POOL_NAME=locations/global/workforcePools/XXXXX-wfif-pool
cat <<EOF > iap_settings.yaml
access_settings:
  identity_sources: ["WORKFORCE_IDENTITY_FEDERATION"]
  workforce_identity_settings:
    workforce_pools: ["$WORKFORCE_POOL_NAME"]
    oauth2:
      client_id: "$CLIENT_ID"
      client_secret: "$CLIENT_SECRET"
EOF

and execute the following:

gcloud iap settings set iap_settings.yaml --project=<YOUR_PROJECT_ID> --resource-type=iap_web --service=compute
```

7. Open a web browser, and point it to your applicaion DNS. It should bring up your external IDP for authentication. Following this you should be redirected to your VMs Instance Group.
