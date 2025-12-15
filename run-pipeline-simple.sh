#!/bin/bash
# Run the simplified all-in-one pipeline (bypasses emptyDir issue)

set -e

echo "=========================================="
echo "🚀 Simplified Pipeline Runner"
echo "=========================================="
echo "This uses a single task for clone+lint+test"
echo "to bypass the emptyDir persistence issue"
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

# Apply the all-in-one task
echo "📦 Applying all-in-one task..."
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
echo "This pipeline combines clone+lint+test into ONE task,"
echo "so all files stay in the same pod workspace."
echo ""
echo "To view pipeline runs:"
echo "  oc get pipelinerun"
echo ""
echo "To follow the logs:"
echo "  tkn pipelinerun logs -f --last"
echo ""

