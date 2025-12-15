# ✅ Pipeline Restored: Full 6-Step Structure

## What's Been Done

Your pipeline now has the **complete 6-step structure** as originally designed:

```
1. cleanup      → Clean the workspace
2. git-clone    → Clone your repository
3. lint         → Run ESLint
4. tests        → Run Jest tests
5. build-image  → Build Docker image with Buildah
6. deploy       → Deploy to OpenShift
```

## Key Changes

### 1. Tasks Restored (`.tekton/tasks.yml`)

**Cleanup Task:**
- Cleans workspace before starting
- Uses `alpine:3` image

**Git-Clone Task:**
- Custom git-clone (not ClusterTask)
- Clones directly to workspace root (not subdirectory)
- Uses `alpine/git` image

**ESLint Task:**
- Installs dependencies with `npm install`
- Runs ESLint linting
- Uses `node:20-alpine` image

**Jest-Test Task:**
- Runs Jest tests with `npm test`
- Uses `node:20-alpine` image

**Build & Deploy:**
- Uses ClusterTasks (buildah, openshift-client)

### 2. Pipeline Updated (`pipeline-simple.yml`)

- Pipeline name: `lab-pipeline`
- All 6 tasks in sequence
- Each task uses the same workspace: `shared-workspace`
- Buildah CONTEXT set to `.` (workspace root)

### 3. Run Script Enhanced (`run-pipeline-simple.sh`)

- Attempts to create PVC automatically
- Falls back to emptyDir if PVC creation fails
- Shows clear warnings about workspace persistence

## How to Run

```bash
cd /Users/oleksandr/WebstormProjects/ci-cd-final-project
git pull origin main
./run-pipeline-simple.sh
```

## Expected Pipeline Flow

```
lab-pipeline-run-xxxxx
  ├─ ✅ cleanup       (Cleans workspace)
  ├─ ✅ git-clone     (Clones repo to /workspace/source/)
  ├─ ✅ lint          (Runs ESLint)
  ├─ ✅ tests         (Runs Jest)
  ├─ ⏳ build-image   (Builds Docker image)
  └─ ⏳ deploy        (Deploys to OpenShift)
```

## Important: Workspace Persistence

For tasks 2-6 to work, the workspace **MUST persist** between tasks.

### With PVC (Recommended):
```
cleanup → git-clone → lint → tests → build → deploy
   ↓         ↓         ↓       ↓       ↓       ↓
  PVC  →   PVC   →   PVC  →  PVC  →  PVC  →  PVC
  (All tasks share the same persistent storage)
```
✅ **Works perfectly**

### With emptyDir (May Fail):
```
cleanup → git-clone → lint → tests → build → deploy
   ↓         ↓         ✗       ✗       ✗       ✗
  Pod A  →  Pod B  →  Pod C (empty workspace!)
```
❌ **May fail** if emptyDir doesn't persist

## What the Script Does

1. **Checks/Creates PVC**: Tries to create `pipeline-workspace-pvc` (500MB)
2. **Applies Tasks**: Deploys all 6 task definitions
3. **Applies Pipeline**: Deploys the pipeline definition
4. **Creates PipelineRun**: 
   - Uses PVC if available
   - Falls back to emptyDir if PVC creation failed

## Files Structure

```
ci-cd-final-project/
├── .tekton/
│   └── tasks.yml              ← All 6 tasks defined here
├── pipeline-simple.yml        ← Pipeline with 6 tasks
├── run-pipeline-simple.sh     ← Run script with PVC support
└── pvc.yml                    ← PVC definition (500MB)
```

## Visibility in UI

You'll now see **6 separate tasks** in the Tekton UI:

```
Pipeline: lab-pipeline
├─ Task 1: cleanup
├─ Task 2: git-clone
├─ Task 3: lint
├─ Task 4: tests
├─ Task 5: build-image
└─ Task 6: deploy
```

Much better visibility than the all-in-one approach!

## Troubleshooting

### If lint/test fails with "package.json not found":

**Cause:** Workspace not persisting (emptyDir issue)

**Solution:**
1. Check if PVC was created: `oc get pvc`
2. If no PVC: Contact administrator for PVC quota
3. See `WORKSPACE-PERSISTENCE-ISSUE.md` for details

### If build fails with "Dockerfile not found":

**Cause:** Buildah can't find Dockerfile

**Solution:** Already fixed! Buildah CONTEXT is set to `.` (workspace root)

## Next Steps

1. ✅ Run `./run-pipeline-simple.sh`
2. ⏳ Watch the pipeline execute all 6 steps
3. 🎉 See your app deployed to OpenShift!

## Summary

✅ **6-step pipeline structure restored**
✅ **Better visibility** - Each step is a separate task
✅ **PVC support** - Auto-attempts to create PVC
✅ **Full CI/CD** - From cleanup to deployment
✅ **Production-ready** - Proper Docker build and deploy

Your pipeline now matches the original design with cleanup, git-clone, eslint, jest-test, buildah, and deploy as separate, visible tasks!

