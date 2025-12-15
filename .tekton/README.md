# CI/CD Tools and Practices Final Project Tekton Workflows

This directory contains all the Tekton workflows for the CI/CD Tools and Practices Final Project for the Node.js Counter Service.

## Important: Repository URL Configuration

⚠️ **CRITICAL:** Before running the pipeline, you MUST update the `repo-url` parameter to point to your Node.js repository that contains `package.json`.

The pipeline is designed for a **Node.js/JavaScript project**, not a Python project.

### How to Run the Pipeline

When creating a PipelineRun, you must specify the `repo-url` parameter with your Node.js repository:

```yaml
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  name: lab-pipeline-run
spec:
  pipelineRef:
    name: lab-pipeline
  params:
    - name: repo-url
      value: "https://github.com/YOUR-USERNAME/YOUR-NODEJS-REPO"  # ← UPDATE THIS
    - name: branch
      value: "main"
    - name: build-image
      value: "image-registry.openshift-image-registry.svc:5000/YOUR-NAMESPACE/YOUR-APP:latest"
    - name: app-name
      value: "counter-service"
  workspaces:
    - name: output
      volumeClaimTemplate:
        spec:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 1Gi
```

### What This Pipeline Does

1. **Cleanup** - Removes all files from the workspace
2. **Git Clone** - Clones your Node.js repository
3. **Lint** - Runs ESLint on your code
4. **Test** - Runs Jest tests
5. **Build Image** - Builds a container image using Buildah
6. **Deploy** - Deploys to OpenShift
