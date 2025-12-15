# CRITICAL FIX: Apply Updated Tasks

## The Issue
You're running the OLD version of the tasks in OpenShift that still reference `workspaces.source.path`.
The error `/tekton/scripts/script-0-gcdv5: line 23: workspaces.source.path: not found` proves this.

## The Fix
I've fixed the last remaining reference to `workspaces.source.path` in the eslint task.
Now ALL tasks use `workspaces.output.path`.

## YOU MUST DO THIS NOW:

### Step 1: Pull Latest Changes and Apply
```bash
cd /Users/oleksandr/WebstormProjects/ci-cd-final-project
./apply-and-run.sh
```

This script will:
1. ✅ Pull the latest fixes from GitHub
2. ✅ Apply the updated tasks to OpenShift (replacing the old ones)
3. ✅ Apply the updated pipeline
4. ✅ Run a new PipelineRun

### Step 2: Verify Tasks Were Applied
```bash
# Check that the tasks were updated
oc get task cleanup -o yaml | grep "name: output"
oc get task eslint -o yaml | grep "name: output"  
oc get task jest-test -o yaml | grep "name: output"
```

All three should show `name: output` in their workspace definition.

## What Was Fixed in This Final Update:

### File: `.tekton/tasks.yml`
**Line 74** - eslint task auto-detection code:
```yaml
# BEFORE (WRONG):
PACKAGE_JSON=$(find $(workspaces.source.path) -maxdepth 2 -name "package.json" -type f | head -1)

# AFTER (CORRECT):
PACKAGE_JSON=$(find $(workspaces.output.path) -maxdepth 2 -name "package.json" -type f | head -1)
```

## Why This Matters:
- The git-clone task clones to `/workspace/output/`
- Your tasks MUST look in `/workspace/output/`
- Using `workspaces.source.path` tries to access a non-existent variable
- This causes the script to fail before it can find the files

## After Running apply-and-run.sh:
The pipeline will:
1. ✅ Cleanup `/workspace/output/`
2. ✅ Clone repository to `/workspace/output/`
3. ✅ Find `package.json` in `/workspace/output/`
4. ✅ Run ESLint successfully
5. ✅ Run Jest tests successfully
6. ✅ Build and deploy

## If It Still Fails:
Check the git-clone logs to confirm files were cloned:
```bash
# Get the latest pipeline run name
LATEST_RUN=$(oc get pipelinerun --sort-by=.metadata.creationTimestamp -o name | tail -1)

# Check git-clone logs
oc logs ${LATEST_RUN}-git-clone-pod

# Check lint logs
oc logs ${LATEST_RUN}-lint-pod
```

The git-clone logs should show:
```
Successfully cloned https://github.com/oleksandr-khoma/ci-cd-final-project.git ... in path /workspace/output/
```

The lint logs should NOW show files in `/workspace/output/` instead of an empty directory.

