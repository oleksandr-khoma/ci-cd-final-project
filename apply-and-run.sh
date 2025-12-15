#!/bin/bash
# Quick fix script to apply updated tasks and run pipeline

set -e

echo "=========================================="
echo "🔧 Applying Workspace Fix"
echo "=========================================="
echo ""

# Apply the fixed tasks
echo "📦 Applying updated tasks..."
oc apply -f .tekton/tasks.yml

# Apply the fixed pipeline
echo "📦 Applying updated pipeline..."
oc apply -f pipeline.yml

echo ""
echo "✅ Tasks and pipeline updated!"
echo ""
echo "=========================================="
echo "🚀 Running Pipeline"
echo "=========================================="
echo ""

# Run the pipeline
./run-pipeline.sh

