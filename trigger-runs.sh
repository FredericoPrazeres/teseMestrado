#!/bin/bash
#
# trigger-runs.sh
# Triggers multiple CI pipeline runs by pushing empty commits periodically.
#
# Usage:
#   ./trigger-runs.sh              # uses defaults
#   ./trigger-runs.sh 5            # 5 runs
#   ./trigger-runs.sh 5 120        # 5 runs, 120 seconds between each
#

# ─── Configuration ───────────────────────────────────────────────────────────

NUM_RUNS=${1:-5}              # Number of pipeline runs to trigger (default: 5)
INTERVAL_SECONDS=${2:-120}     # Seconds to wait between pushes (default: 120)
BRANCH="applications/home-assistant-core" # Branch to push to

# ─── Script ──────────────────────────────────────────────────────────────────

echo "============================================"
echo "  CI Pipeline Trigger Script"
echo "============================================"
echo "  Runs to trigger : $NUM_RUNS"
echo "  Interval        : ${INTERVAL_SECONDS}s between pushes"
echo "  Branch           : $BRANCH"
echo "  Started at       : $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================"
echo ""

for i in $(seq 1 "$NUM_RUNS"); do
    echo "──────────────────────────────────────────"
    echo "  Run $i / $NUM_RUNS"
    echo "  $(date '+%Y-%m-%d %H:%M:%S')"
    echo "──────────────────────────────────────────"

    # Create an empty commit to trigger the pipeline
    git commit --allow-empty -m "MacOS Github Job Test - $i/$NUM_RUNS"

    # Push to remote
    if git push origin "$BRANCH"; then
        echo "✅ Run $i/$NUM_RUNS pushed successfully"
    else
        echo "❌ Run $i/$NUM_RUNS push failed!"
        exit 1
    fi

    # Wait before the next push (skip wait after the last run)
    if [ "$i" -lt "$NUM_RUNS" ]; then
        echo "⏳ Waiting ${INTERVAL_SECONDS}s before next push..."
        sleep "$INTERVAL_SECONDS"
    fi

    echo ""
done

echo "============================================"
echo "  All $NUM_RUNS runs triggered successfully!"
echo "  Finished at: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================"