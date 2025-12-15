#!/bin/bash
# Quick fix script to apply updated tasks and run pipeline

set -e

echo "=========================================="
echo "🔧 Pulling Latest Changes & Applying Fixes"
echo "=========================================="
echo ""

# Pull latest changes from git
echo "📥 Pulling latest changes from GitHub..."
git pull origin main

echo ""
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

