# How to Run the Tekton Pipeline

## Step 1: Apply the Pipeline and Tasks to OpenShift

```bash
# Make sure you're in the correct OpenShift project
oc project YOUR-PROJECT-NAME

# Apply the tasks
oc apply -f .tekton/tasks.yml

# Apply the pipeline
oc apply -f pipeline.yml
```

## Step 2: Create and Run the PipelineRun

### Option A: Using the CLI (Recommended for First Run)

```bash
# Get your current namespace
NAMESPACE=$(oc project -q)

# Create the PipelineRun with the correct parameters
oc create -f - <<EOF
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: lab-pipeline-run-
spec:
  pipelineRef:
    name: lab-pipeline
  params:
    - name: repo-url
      value: "https://github.com/oleksandr-khoma/ci-cd-final-project.git"
    - name: branch
      value: "main"
    - name: build-image
      value: "image-registry.openshift-image-registry.svc:5000/\${NAMESPACE}/counter-app:latest"
    - name: app-name
      value: "counter-app"
  workspaces:
    - name: output
      emptyDir: {}
EOF
```

### Option B: Update pipelinerun.yml and Apply

1. Edit `pipelinerun.yml` and replace `YOUR-NAMESPACE` with your actual OpenShift namespace
2. Run: `oc create -f pipelinerun.yml`

## Step 3: Monitor the Pipeline

```bash
# List all pipeline runs
oc get pipelinerun

# Watch the latest pipeline run
oc logs -f pipelinerun/lab-pipeline-run-XXXXX

# Or use tkn CLI if installed
tkn pipelinerun logs -f --last
```

## Troubleshooting

### Error: "package.json not found" or "Python repository detected"

This means the wrong repository is being cloned. **Verify:**

1. The `repo-url` parameter is set to: `https://github.com/oleksandr-khoma/ci-cd-final-project.git`
2. You're NOT using the old default URL: `https://github.com/ibm-developer-skills-network/wtecc-CICD_PracticeCode`

### How to Delete Old/Failed Pipeline Runs

```bash
# Delete a specific pipeline run
oc delete pipelinerun lab-pipeline-run-XXXXX

# Delete all completed pipeline runs
oc delete pipelinerun --field-selector=status.conditions[0].status==True

# Delete all failed pipeline runs
oc delete pipelinerun --field-selector=status.conditions[0].status==False
```

### Verify the Repository URL Being Used

Check the PipelineRun spec:

```bash
oc get pipelinerun lab-pipeline-run-XXXXX -o jsonpath='{.spec.params[?(@.name=="repo-url")].value}'
```

It should output: `https://github.com/oleksandr-khoma/ci-cd-final-project.git`

