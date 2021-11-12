#!/bin/sh
# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

####################################
### function: generate_edge_json ###
####################################
generate_edge_json() {
  ENV_NAME=$1
  cat <<EOF >> "$SCRIPTPATH/api-proxy-v1/edge.json"
{
    "version": "1.0",
    "envConfig": {
        "$ENV_NAME": {
            "caches": [
            {
                "name": "gcp-tokens",
                "description": "Cahe for GCP Tokens",
                "expirySettings": {
                    "timeoutInSec": {
                        "value": "300"
                    },
                    "valuesNull": false
                }
            }
            ],
            "kvms": [
			      {
                "name": "oas-mock-target-service-accounts",
                "encrypted": "true",
                "entry": [
                {
                    "name": "cloud-run",
                    "value": $GCP_SA_KEY
                }
			          ]
			      }
            ]
        }
    }
}
EOF
}

###
# Apigee Mock Target 
###

set -e

SCRIPTPATH="$( cd "$(dirname "$0")" || exit >/dev/null 2>&1 ; pwd -P )"

###
# Check for required variables
###

if [ -z "$OPEN_API_SPEC_MOCK"   ] || \
   [ -z "$GCP_PROJECT" 	       ]; then
  echo "A required variable is missing";
  exit 1
fi

###
# Manage optional variables
###

GCP_REGION=${GCP_REGION:-europe-west1}

###
# Check for required tools on path
###

for TOOL in gcloud jq node npm sackmesser xmllint; do
  if ! which $TOOL > /dev/null; then
    echo "Please ensure $TOOL is installed and on your PATH"
    exit 1
  fi
done

###
# Push Mock Target Image
###

gcloud services enable containerregistry.googleapis.com run.googleapis.com
gcloud auth configure-docker -q

cat > Dockerfile <<EOF
FROM node:12-alpine3.11
WORKDIR /usr/src/app
ADD package.json ./
ADD $OPEN_API_SPEC_MOCK ./openapi.yaml
RUN npm install --only=production
COPY . ./
CMD [ "node", "app.js" ]
EOF

docker build -t gcr.io/"$GCP_PROJECT"/apigee-mock-target:latest .
docker push gcr.io/"$GCP_PROJECT"/apigee-mock-target:latest

###
# Deploy Mock Target on Cloud Run 
###

gcloud run deploy apigee-mock-target \
--image=gcr.io/"$GCP_PROJECT"/apigee-mock-target \
--platform=managed \
--region="$GCP_REGION" \
--no-allow-unauthenticated

TARGET_URL=$(gcloud run services describe apigee-mock-target --platform managed --region "$GCP_REGION" --format json | jq -r '.status.url')


###
## Generate Service Account for Apigee to call Cloud Run
###

gcloud iam service-accounts create oas-mock-target-sa \
--project "$GCP_PROJECT" || true

gcloud iam service-accounts keys create credentials.json \
--iam-account oas-mock-target-sa@"$GCP_PROJECT".iam.gserviceaccount.com

# Get the GCP SA Key from the credentials.json file
GCP_SA_KEY=$(jq '. | tostring' < "./credentials.json")

gcloud run services add-iam-policy-binding apigee-mock-target \
--region "$GCP_REGION" \
--member serviceAccount:oas-mock-target-sa@"$GCP_PROJECT".iam.gserviceaccount.com \
--role roles/run.invoker \
--platform managed

###
# Deploy Shared Flow to manage JWT token 
###

sh "$SCRIPTPATH"/../../references/gcp-sa-auth-shared-flow/deploy.sh --googleapi

###
# Generate the Apigee Proxy
###

cp -r "$SCRIPTPATH"/proxy api-proxy-v1

# generate edge.json file
generate_edge_json "$APIGEE_X_ENV"

sed -i.bak "s|@TargetURL@|$TARGET_URL|" ./api-proxy-v1/apiproxy/targets/default.xml
sed -i.bak "s|@TargetURL@|$TARGET_URL|" ./api-proxy-v1/apiproxy/policies/AM.GCPAudience.xml
rm ./api-proxy-v1/apiproxy/targets/default.xml.bak ./api-proxy-v1/apiproxy/policies/AM.GCPAudience.xml.bak

###
# deploy apigee proxy to Apigee X or hybrid
###
echo "[INFO] Deploying Mock Target Proxy to Google API (For X/hybrid)"
APIGEE_TOKEN=$(gcloud auth print-access-token);

sackmesser deploy --googleapi -o "$APIGEE_X_ORG" -e "$APIGEE_X_ENV" -t "$APIGEE_TOKEN" -h "$APIGEE_X_HOSTNAME" -d "$SCRIPTPATH/api-proxy-v1"

### print result
echo "Successfully deployed Mock Target ($OPEN_API_SPEC_MOCK) for Apigee API Proxy"
