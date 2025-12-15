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

# Apply the 3 tasks
echo "📦 Applying 3 tasks (clone, lint, test)..."
oc apply -f .tekton/all-in-one-task.yml

# Apply the simplified pipeline
echo "📦 Applying simplified pipeline..."
oc apply -f pipeline-simple.yml

echo ""
echo "🚀 Creating PipelineRun..."
echo ""

# Create the PipelineRun with emptyDir (works because everything is in one task)
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

echo ""
echo "=========================================="
echo "✅ Simplified pipeline started!"
echo "=========================================="
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

