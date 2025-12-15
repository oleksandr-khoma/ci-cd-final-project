#!/bin/bash
# Script to run the Tekton pipeline with correct parameters

set -e

echo "=========================================="
echo "Tekton Pipeline Runner"
echo "=========================================="
echo ""

# Get current namespace
NAMESPACE=$(oc project -q 2>/dev/null)

if [ -z "$NAMESPACE" ]; then
    echo "❌ Error: Not logged into OpenShift"
    echo "Please run: oc login <your-cluster-url>"
    exit 1
fi

echo "✅ Current OpenShift namespace: $NAMESPACE"
echo ""

# Verify we're using the correct repository
REPO_URL="https://github.com/oleksandr-khoma/ci-cd-final-project.git"
echo "✅ Repository URL: $REPO_URL"
echo ""

# Apply tasks and pipeline
echo "📦 Applying Tekton tasks..."
oc apply -f .tekton/tasks.yml

echo "📦 Applying pipeline..."
oc apply -f pipeline.yml

echo ""
echo "🚀 Creating PipelineRun..."
echo ""

# Create the PipelineRun
cat <<EOF | oc create -f -
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: lab-pipeline-run-
spec:
  pipelineRef:
    name: lab-pipeline
  params:
    - name: repo-url
      value: "$REPO_URL"
    - name: branch
      value: "main"
    - name: build-image
      value: "image-registry.openshift-image-registry.svc:5000/$NAMESPACE/counter-app:latest"
    - name: app-name
      value: "counter-app"
  workspaces:
    - name: output
      persistentVolumeClaim:
        claimName: pipeline-workspace-pvc
EOF

echo ""
echo "=========================================="
echo "✅ Pipeline started successfully!"
echo "=========================================="
echo ""
echo "To view the pipeline run:"
echo "  oc get pipelinerun"
echo ""
echo "To follow the logs:"
echo "  tkn pipelinerun logs -f --last"
echo "  # OR"
echo "  oc logs -f \$(oc get pipelinerun -o name | tail -1)"
echo ""

