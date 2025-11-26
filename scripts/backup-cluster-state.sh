#!/bin/bash

CLUSTERS="$1"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
S3_BUCKET=${S3_BACKUP_BUCKET:-"eks-auto-mode-backups"}

for CLUSTER_NAME in $CLUSTERS; do
    echo "Backing up cluster: $CLUSTER_NAME"
    BACKUP_DIR="backup-$CLUSTER_NAME-$TIMESTAMP"
    mkdir -p $BACKUP_DIR

    # Update kubeconfig for cluster
    aws eks update-kubeconfig --name $CLUSTER_NAME --region ${AWS_REGION:-us-east-1}

    # Backup cluster configuration
    aws eks describe-cluster --name $CLUSTER_NAME > $BACKUP_DIR/cluster-config.json

    # Backup node groups
    aws eks list-nodegroups --cluster-name $CLUSTER_NAME --query 'nodegroups[]' --output text | while read nodegroup; do
        if [ ! -z "$nodegroup" ]; then
            aws eks describe-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name $nodegroup > $BACKUP_DIR/nodegroup-$nodegroup.json
        fi
    done

    # Backup Kubernetes resources
    kubectl get nodes -o yaml > $BACKUP_DIR/nodes.yaml
    kubectl get pods -A -o yaml > $BACKUP_DIR/pods.yaml


    # Backup Helm releases
    helm list -A -o json > $BACKUP_DIR/helm-releases.json

    # Backup custom resources
    kubectl get crd -o yaml > $BACKUP_DIR/custom-resources.yaml

    # Upload to S3
    aws s3 cp $BACKUP_DIR s3://$S3_BUCKET/$CLUSTER_NAME-$TIMESTAMP/ --recursive
    echo "✅ Backup completed for $CLUSTER_NAME: $BACKUP_DIR"
done