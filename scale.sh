#!/bin/bash

set -e

if ! type gum &> /dev/null; then
  echo "Error: Gum is not installed. Run 'brew install gum'"
  exit 1
fi

if [ "$AWS_VAULT" != "bridge" ]; then
  echo "Error: Run with aws-vault exec bridge!"
  exit 1
fi

echo "Choose an Truss Environment:"
trussEnv=$(gum filter --height=6 "nonprod-cmh" "nonprod-dub" "nonprod-syd" "prod-cmh" "prod-dub" "prod-syd")
echo "> $trussEnv"
export KUBECONFIG=~/.kube/configs/kubeconfig-truss-tailscale-$trussEnv

echo "Choose an App Environment:"
if [[ $trussEnv == *"nonprod"* ]]; then
  appEnv=$(gum choose "edge" "staging")
else
  appEnv=$(gum choose "prod")
fi
echo "> $appEnv"

echo "Choose App Namespace:"
appNamespace=$(gum choose \
  "bridge-api-auth-$appEnv" \
  "authmonger-$appEnv" \
  "bridge-tagging-service-$appEnv" \
  "data-report-$appEnv" \
  "bridge-skills-service-$appEnv" \
  "notification-center-$appEnv")
echo "> $appNamespace"
echo

deployments=$(set -x; gum spin --show-output -- kubectl -n $appNamespace get deployment -o json)
echo "Found Deployments:"
echo $deployments | jq -r '.items[] | .metadata.name + ": " + (.spec.replicas | tostring)'
echo
echo "Set Desired Replicas:"
desiredReplicas=$(gum input --value=0)
echo "> $desiredReplicas"

gum confirm "Scale all deployments to $desiredReplicas?"
(set -x; gum spin -- kubectl -n $appNamespace scale deployment --all --replicas=$desiredReplicas)
echo
echo "All done! 🧙"
