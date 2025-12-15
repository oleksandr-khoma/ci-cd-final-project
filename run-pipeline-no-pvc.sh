#!/bin/bash
# Run pipeline without PVC (uses all-in-one CI task)

set -e

echo "=========================================="
echo "🚀 CI/CD Pipeline Runner (No PVC Required)"
echo "=========================================="
echo "This uses combined CI task (clone+lint+test in ONE pod)"
echo "to work without PVC quota"
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

# Apply the all-in-one CI task
echo "📦 Applying CI all-in-one task..."
oc apply -f .tekton/ci-all-in-one.yml

# Apply the pipeline
echo "📦 Applying pipeline..."
oc apply -f pipeline-no-pvc.yml

echo ""
echo "🚀 Creating PipelineRun..."
echo ""

# Create the PipelineRun with emptyDir
cat <<EOF | oc create -f -
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: lab-pipeline-run-
spec:
  pipelineRef:
    name: lab-pipeline-no-pvc
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
echo "✅ Pipeline started successfully!"
echo "=========================================="
echo ""
echo "This pipeline uses 3 tasks:"
echo "  1. ci (clone → lint → test in ONE pod)"
echo "  2. build-image (buildah)"
echo "  3. deploy (openshift-client)"
echo ""
echo "The CI task combines clone+lint+test into ONE pod,"
echo "so files persist without needing PVC!"
echo ""
echo "To view pipeline runs:"
echo "  oc get pipelinerun"
echo ""
echo "To follow the logs:"
echo "  tkn pipelinerun logs -f --last"
echo "  # OR"
echo "  LATEST=\$(oc get pipelinerun --sort-by=.metadata.creationTimestamp -o name | tail -1)"
echo "  oc logs -f \${LATEST}-ci-pod"
echo ""

