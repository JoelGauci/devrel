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

# A script to clean up entities that can't be updated - errors may indicate that entities are already removed
SCRIPTPATH="$( cd "$(dirname "$0")" || exit >/dev/null 2>&1 ; pwd -P )"

###
# Manage optional variables
###
GCP_REGION=${GCP_REGION:-europe-west1}


# Cleanup Apigee Assets - TODO switch to sackmesser for 5g cleanup
#npx apigeetool undeploy -u "$APIGEE_USER" -p "$APIGEE_PASS" -o "$APIGEE_ORG" -e "$APIGEE_ENV" -n "api-proxy-v1"
#npx apigeetool delete -u "$APIGEE_USER" -p "$APIGEE_PASS" -o "$APIGEE_ORG" -n "api-proxy-v1"
#npx apigeetool undeploySharedflow -u "$APIGEE_USER" -p "$APIGEE_PASS" -o "$APIGEE_ORG" -e "$APIGEE_ENV" -n "gcp-sa-auth-v1"
#npx apigeetool deleteSharedFlow -u "$APIGEE_USER" -p "$APIGEE_PASS" -o "$APIGEE_ORG" -n "gcp-sa-auth-v1"
#npx apigeetool deletecache -u "$APIGEE_USER" -p "$APIGEE_PASS" -o "$APIGEE_ORG" -e "$APIGEE_ENV" -z "gcp-tokens"
#npx apigeetool deletekvmmap -u "$APIGEE_USER" -p "$APIGEE_PASS" -o "$APIGEE_ORG" -e "$APIGEE_ENV" --mapName "oas-mock-target-service-accounts"


# Delete generated API Proxy
rm -r "$SCRIPTPATH"/api-proxy-v1

# Remove Dockerfile
rm Dockerfile

###
# delete the API proxy proxy from Apigee X or hybrid
###
echo "[INFO] Deleting Mock Target Proxy from Apigee (X/hybrid)"
APIGEE_TOKEN=$(gcloud auth print-access-token);
sackmesser clean --googleapi -t "$APIGEE_TOKEN" proxy apigee-oas-target-v1

# Cleanup  GCP Assets
gcloud run services delete apigee-mock-target --region "$GCP_REGION" -q
gcloud iam service-accounts delete oas-mock-target-sa@"$GCP_PROJECT".iam.gserviceaccount.com --project "$GCP_PROJECT" -q


