# CRITICAL ISSUE: EmptyDir Doesn't Persist Between Tasks

## The Root Cause (FINALLY IDENTIFIED!)

Your OpenShift/Kubernetes environment **does NOT support emptyDir persistence between task pods**.

### What's Happening:
1. ✅ git-clone task runs → clones files to `/workspace/output/` → SUCCESS
2. ❌ eslint task starts → gets a **NEW EMPTY** `/workspace/output/` → FAIL

### Why This Happens:
In standard Tekton, `emptyDir` workspaces are supposed to persist across tasks in the same PipelineRun. However, in some Kubernetes/OpenShift environments (especially shared lab environments), each task pod gets its own isolated emptyDir volume that doesn't share data.

### Evidence from Your Logs:

**Git-Clone Logs:**
```
Successfully cloned https://github.com/oleksandr-khoma/ci-cd-final-project.git @ ed3d5de... in path /workspace/output/
```
✅ Files ARE cloned successfully!

**Lint Task Logs:**
```
Files in current directory:
total 8
drwxrwsrwx    2 root     1000730000      4096 Dec 15 12:52 .
drwxrwsrwx    3 root     1000730000      4096 Dec 15 12:52 ..
```
❌ Workspace is completely empty!

## The Solution: Use PersistentVolumeClaim (PVC)

You MUST use a PVC instead of emptyDir for the workspace to persist between tasks.

### Option 1: Try Creating a Small PVC (Preferred)

```bash
# Try to create a small 500MB PVC
oc apply -f pvc.yml

# If successful, run the pipeline
./run-pipeline-advanced.sh
```

The new `run-pipeline-advanced.sh` script will:
- ✅ Try to create/use a PVC automatically
- ✅ Fall back to emptyDir if PVC creation fails
- ✅ Warn you if using emptyDir

### Option 2: If PVC Creation Fails (Quota Exceeded)

You have two choices:

#### A) Request Quota Increase
Contact your OpenShift administrator and request:
- Permission to create 1 PVC
- Size: 500MB (minimal)
- Purpose: Tekton pipeline workspace

#### B) Use a Different Approach (Workaround)
Since tasks can't share workspace, we need to combine all steps into a SINGLE task:
- Clone repository
- Run linting  
- Run tests
- Build image

This way everything happens in one pod with one workspace.

## Why We Couldn't Solve This Earlier:

1. First we had workspace NAME mismatch (`source` vs `output`) ✅ FIXED
2. Then we had script errors with `workspaces.source.path` ✅ FIXED
3. NOW we discover the environment doesn't support emptyDir persistence ❌ INFRASTRUCTURE LIMITATION

This is a **fundamental limitation of your OpenShift environment**, not a bug in your configuration.

## Next Steps:

### Try Option 1 First:
```bash
cd /Users/oleksandr/WebstormProjects/ci-cd-final-project
./run-pipeline-advanced.sh
```

This script will automatically try to use PVC if possible.

### If That Fails:
You'll see this message:
```
⚠️  PVC creation failed (quota limit reached)
⚠️  You'll need to request PVC quota increase from your administrator.
```

Then you need to contact your administrator or use the single-task workaround approach.

## Why EmptyDir Works in Tutorials But Not Here:

Most Tekton tutorials assume:
- Local Kubernetes clusters (minikube, kind)
- Cloud providers with full PVC support
- Non-restrictive environments

Your IBM Skills Network lab environment has:
- Quota restrictions
- Isolated task pods
- EmptyDir that doesn't persist between pods

This is a **known limitation** of shared lab environments.

