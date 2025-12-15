#!/bin/bash
# Run the full 6-step pipeline with PVC support

set -e

echo "=========================================="
echo "🚀 CI/CD Pipeline Runner"
echo "=========================================="
echo "Full pipeline: cleanup → git-clone → lint → test → build → deploy"
echo "Attempts to use PVC for workspace persistence"
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

# Apply the tasks
echo "📦 Applying tasks (cleanup, git-clone, eslint, jest-test)..."
oc apply -f .tekton/tasks.yml

# Apply the pipeline
echo "📦 Applying pipeline..."
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
echo "This pipeline uses the full 6-step structure:"
echo "that share the same workspace for better visibility."
echo ""
echo "You'll see 6 separate task executions in the UI/logs:"
echo "  1. cleanup"
echo "  2. git-clone"
echo "  3. lint (eslint)"
echo "  4. tests (jest-test)"
echo "  5. build-image (buildah)"
echo "  6. deploy (openshift-client)"
echo ""
echo "To view pipeline runs:"
echo "  oc get pipelinerun"
echo ""
echo "To follow the logs:"
echo "  tkn pipelinerun logs -f --last"
echo ""

