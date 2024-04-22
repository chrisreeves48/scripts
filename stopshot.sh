#!/bin/bash

set -e

if ! type gum &> /dev/null; then
  echo "Error: Gum is not installed. Run 'brew install gum'"
  exit 1
fi

if [ "$AWS_VAULT" != "bridge-shared" ]; then
  echo "Error: Run with aws-vault exec bridge-shared!"
  exit 1
fi

#target instance
echo "Choose a Region:"
region=$(gum choose "us-east-2" "eu-west-1" "ap-southeast-2")
echo "> $region"
export AWS_REGION=$region


echo "Choose an App Environment:"
  appEnv=$(gum choose "edge" "staging" "prod")
echo "> $appEnv"

clusters=$(set -x ; gum spin --show-output -- aws rds describe-db-clusters)
clusternames=($(echo $clusters | jq -r '.DBClusters[].DBClusterIdentifier'))

echo "Choose a Cluster:"
cluster=$(gum choose "${clusternames[@]}")
echo "> $cluster"

gum confirm "Would you like to shutdown the cluster: $cluster?"
echo "Shutting down cluster:"
# (set -x ; gum spin --show-output -- aws rds stop-db-cluster --db-cluster-identifier $cluster)
#Take Snapshot

gum confirm "Would you like to take a snapshot of: $cluster?"
snapshotIdentifier="$cluster-$(date "+%Y-%m-%d_%H-%M-%S")-upgrade"
# (set -x ; gum spin --show-output -- aws rds create-db-cluster-snapshot --db-cluster-snapshot-identifier "aurora-$appEnv-snapshot" --db-cluster-identifier $cluster)
echo "Snapshotting $cluster!"

gum confirm "Have you included the Snapshot Identifier \n in your Terraform yet? $snapshotIdentifier"


