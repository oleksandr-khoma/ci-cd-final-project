#!/bin/bash
# Comprehensive pipeline runner with PVC management

set -e

echo "=========================================="
echo "🔧 Tekton Pipeline Setup & Runner"
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

# Repository URL
REPO_URL="https://github.com/oleksandr-khoma/ci-cd-final-project.git"
echo "✅ Repository URL: $REPO_URL"
echo ""

# Step 1: Try to create or use existing PVC
echo "=========================================="
echo "📦 Step 1: Workspace PVC Setup"
echo "=========================================="
echo ""

PVC_NAME="pipeline-workspace-pvc"
USE_PVC=false

if oc get pvc $PVC_NAME &>/dev/null; then
  echo "✅ PVC '$PVC_NAME' already exists"
  USE_PVC=true
else
  echo "Attempting to create PVC..."
  if oc apply -f pvc.yml 2>/dev/null; then
    echo "✅ PVC created successfully"
    USE_PVC=true
    sleep 2  # Wait for PVC to be ready
  else
    echo "⚠️  PVC creation failed (quota limit reached)"
    echo "⚠️  Will attempt to use emptyDir (may not work in this environment)"
    USE_PVC=false
  fi
fi

echo ""

# Step 2: Apply tasks and pipeline
echo "=========================================="
echo "📦 Step 2: Apply Tekton Resources"
echo "=========================================="
echo ""

echo "Applying tasks..."
oc apply -f .tekton/tasks.yml

echo "Applying pipeline..."
oc apply -f pipeline.yml

echo "✅ Tekton resources updated"
echo ""

# Step 3: Create PipelineRun
echo "=========================================="
echo "🚀 Step 3: Create PipelineRun"
echo "=========================================="
echo ""

if [ "$USE_PVC" = true ]; then
  echo "Using PVC workspace: $PVC_NAME"
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
        claimName: $PVC_NAME
EOF
else
  echo "Using emptyDir workspace (may not persist between tasks)"
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
      emptyDir: {}
EOF
fi

echo ""
echo "=========================================="
echo "✅ Pipeline started successfully!"
echo "=========================================="
echo ""
echo "To view pipeline runs:"
echo "  oc get pipelinerun"
echo ""
echo "To follow the logs:"
echo "  tkn pipelinerun logs -f --last"
echo "  # OR"
echo "  oc get pipelinerun --sort-by=.metadata.creationTimestamp -o name | tail -1 | xargs oc logs -f"
echo ""

if [ "$USE_PVC" = false ]; then
  echo "⚠️  WARNING: Using emptyDir workspace"
  echo "⚠️  If tasks fail with 'package.json not found', this environment"
  echo "⚠️  doesn't support emptyDir persistence between tasks."
  echo "⚠️  You'll need to request PVC quota increase from your administrator."
  echo ""
fi

