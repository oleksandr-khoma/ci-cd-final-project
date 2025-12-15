#!/bin/bash
# Run the simplified 3-task pipeline (bypasses emptyDir issue)

set -e

echo "=========================================="
echo "🚀 Simplified Pipeline Runner"
echo "=========================================="
echo "This uses 3 tasks (clone, lint, test) that"
echo "share the same workspace to bypass the"
echo "emptyDir persistence issue"
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

# Try to create or use existing PVC
echo "=========================================="
echo "📦 Checking/Creating PVC for Workspace"
echo "=========================================="
PVC_NAME="pipeline-workspace-pvc"
USE_PVC=false

if oc get pvc $PVC_NAME &>/dev/null; then
  echo "✅ PVC '$PVC_NAME' already exists"
  USE_PVC=true
else
  echo "Attempting to create PVC..."
  if oc apply -f pvc.yml 2>&1 | tee /tmp/pvc-create.log; then
    echo "✅ PVC created successfully"
    USE_PVC=true
    sleep 3  # Wait for PVC to be ready
  else
    echo "⚠️  PVC creation failed"
    cat /tmp/pvc-create.log
    echo ""
    echo "⚠️  WARNING: Will use emptyDir (workspace may not persist between tasks)"
    USE_PVC=false
  fi
fi
echo ""

# Apply the 3 tasks
echo "📦 Applying 3 tasks (clone, lint, test)..."
oc apply -f .tekton/all-in-one-task.yml

# Apply the simplified pipeline
echo "📦 Applying simplified pipeline..."
oc apply -f pipeline-simple.yml

echo ""
echo "🚀 Creating PipelineRun..."
echo ""

# Create the PipelineRun
if [ "$USE_PVC" = true ]; then
  echo "Using PVC workspace: $PVC_NAME"
  cat <<EOF | oc create -f -
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: lab-pipeline-simple-run-
spec:
  pipelineRef:
    name: lab-pipeline-simple
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
    - name: shared-workspace
      persistentVolumeClaim:
        claimName: $PVC_NAME
EOF
else
  echo "⚠️  Using emptyDir workspace (may fail if workspace doesn't persist)"
  cat <<EOF | oc create -f -
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: lab-pipeline-simple-run-
spec:
  pipelineRef:
    name: lab-pipeline-simple
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
    - name: shared-workspace
      emptyDir: {}
EOF
fi

echo ""
echo "=========================================="
echo "✅ Simplified pipeline started!"
echo "=========================================="
echo ""
if [ "$USE_PVC" = true ]; then
  echo "✅ Using PVC: Workspace WILL persist between tasks"
else
  echo "⚠️  Using emptyDir: Workspace may NOT persist between tasks"
  echo "⚠️  If lint/test tasks fail with 'repo directory not found',"
  echo "⚠️  you need to request PVC quota from your administrator"
fi
echo ""
echo "This pipeline uses 3 separate tasks (clone, lint, test)"
echo "that share the same workspace for better visibility."
echo ""
echo "You'll see 3 separate task executions in the UI/logs:"
echo "  1. clone (git-clone-repo)"
echo "  2. lint (npm-lint)"
echo "  3. test (npm-test)"
echo ""
echo "To view pipeline runs:"
echo "  oc get pipelinerun"
echo ""
echo "To follow the logs:"
echo "  tkn pipelinerun logs -f --last"
echo ""

