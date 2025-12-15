# CRITICAL: Workspace Not Persisting Between Tasks

## The Problem (Again!)

You're seeing:
```
❌ ERROR: package.json not found!
```

This means the workspace is **NOT persisting** between the `clone` and `lint` tasks.

## Why This Happens

In your OpenShift environment, **emptyDir does NOT persist between different task pods**. Each task gets a fresh empty directory.

### What's Happening:
```
Task 1 (clone):  Pod A → Clones to /workspace/source/repo → Dies
Task 2 (lint):   Pod B → Gets NEW EMPTY /workspace/source → Can't find repo!
```

## The ONLY Solution: Use PVC

You **MUST** use a PersistentVolumeClaim (PVC) for the workspace to persist.

### Try This Now:

```bash
cd /Users/oleksandr/WebstormProjects/ci-cd-final-project
git pull origin main  # Get latest updates
./run-pipeline-simple.sh
```

The updated script will:
1. ✅ Try to create a 500MB PVC automatically
2. ✅ Use PVC if creation succeeds (workspace persists!)
3. ⚠️  Fall back to emptyDir if creation fails (will fail again)

### Expected Output:

#### If PVC Creation Succeeds:
```
📦 Checking/Creating PVC for Workspace
Attempting to create PVC...
✅ PVC created successfully

🚀 Creating PipelineRun...
Using PVC workspace: pipeline-workspace-pvc
✅ Using PVC: Workspace WILL persist between tasks
```

**Result:** Pipeline will work! ✅

#### If PVC Creation Fails:
```
📦 Checking/Creating PVC for Workspace
Attempting to create PVC...
⚠️  PVC creation failed
Error from server (Forbidden): persistentvolumeclaims "..." is forbidden: 
exceeded quota: ...-resourcequota

⚠️  Using emptyDir workspace (may not persist between tasks)
⚠️  WARNING: Will use emptyDir (workspace may not persist between tasks)
```

**Result:** Pipeline will still fail with "package.json not found" ❌

## If PVC Creation Fails: Contact Administrator

You **MUST** contact your OpenShift/IBM Skills Network administrator and request:

### Email Template:
```
Subject: Request PVC Quota for Tekton Pipeline

Hello,

I need permission to create a PersistentVolumeClaim (PVC) for my Tekton CI/CD pipeline workspace.

Details:
- Namespace: sn-labs-oleksandrkh2 (or your namespace)
- PVC Name: pipeline-workspace-pvc
- Size: 500MB (minimal)
- Access Mode: ReadWriteOnce
- Purpose: Tekton pipeline workspace persistence between tasks

Current Error:
"exceeded quota: ...-resourcequota"

Without this PVC, my pipeline tasks cannot share files between them.

Thank you!
```

## Alternative: All Steps in ONE Task (Last Resort)

If you cannot get PVC quota, we need to put ALL steps (clone, lint, test) into a SINGLE task so they share the same pod.

Let me know if PVC creation fails and I'll create this for you.

## Debugging Commands

### Check if PVC was created:
```bash
oc get pvc
```

### Check PVC quota:
```bash
oc describe quota
```

### Check latest pipeline run:
```bash
LATEST=$(oc get pipelinerun --sort-by=.metadata.creationTimestamp -o name | tail -1)
echo $LATEST

# Check clone task (should succeed)
oc logs ${LATEST}-clone-pod

# Check lint task (will fail if no PVC)
oc logs ${LATEST}-lint-pod
```

### Delete failed pipeline runs:
```bash
oc delete pipelinerun --field-selector=status.conditions[0].status==False
```

## Summary

| Solution | Status | Result |
|----------|--------|--------|
| **PVC (Recommended)** | Try automatically | ✅ Works if quota allows |
| **emptyDir** | Won't work | ❌ Workspace doesn't persist |
| **All-in-one task** | Fallback | ✅ Works but less visibility |

## Action Items

1. ✅ Run `./run-pipeline-simple.sh` (tries PVC automatically)
2. ⏳ Check output to see if PVC was created
3. If PVC succeeds: ✅ Done! Pipeline works!
4. If PVC fails: 📧 Contact administrator OR ask me for all-in-one task solution

## Why We Can't Avoid This

This is a **fundamental limitation** of your environment:
- Shared lab/learning environments have strict quotas
- emptyDir doesn't persist across pods in this configuration
- PVC is the standard Kubernetes solution for persistent storage

This is NOT a bug in your pipeline - it's working as designed for your environment's constraints.

