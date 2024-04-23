#!/bin/bash

set -e

if ! type gum &> /dev/null; then
  echo "Error: Gum is not installed. Run 'brew install gum'"
  exit 1
fi

if [ "$AWS_VAULT" != "" ]; then
  echo "Error: Run without aws-vault!"
  exit 1
fi

echo "Choose a Region:"
region=$(gum choose "us-east-2" "eu-west-1" "ap-southeast-2")
echo "> $region"
export AWS_REGION=$region

# Load Clusters
clusters=$(set -x ; gum spin --show-output -- aws-vault exec bridge-shared -- aws rds describe-db-clusters)
clusternames=($(echo $clusters | jq -r '.DBClusters[].DBClusterIdentifier'))

# Select Cluster
echo "Choose a Cluster:"
clustername=$(gum choose "${clusternames[@]}")
echo "> $clustername"
cluster=$(echo $clusters | jq -r ".DBClusters[] | select(.DBClusterIdentifier == \"$clustername\")")

echo
echo "Cluster: $clustername"
echo "ARN: $(echo $cluster | jq -r '.DBClusterArn')"
echo "KmsKeyId: $(echo $cluster | jq -r '.KmsKeyId')"

# Take Snapshot
gum confirm "Would you like to take a snapshot of: $clustername?"
snapshotIdentifier="$clustername-$(date "+%Y-%m-%d-%H%M%S")-upgrade"
echo "DBSnapshotIdentifier: $snapshotIdentifier"
echo
(set -x ; gum spin -- aws-vault exec bridge-shared -- aws rds create-db-cluster-snapshot --db-cluster-snapshot-identifier $snapshotIdentifier --db-cluster-identifier $clustername)
gum confirm "Have you included the Snapshot Identifier in your Terraform yet? $snapshotIdentifier"
(set -x ; gum spin -- aws-vault exec bridge-shared -- aws rds wait db-cluster-snapshot-available --db-cluster-snapshot-identifier $snapshotIdentifier)
echo
echo "Snapshot Complete: $snapshotIdentifier"
