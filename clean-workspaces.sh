#!/bin/bash
#
# clean-workspaces.sh
# Cleans all CI runner workspaces (GitHub, Azure DevOps, Jenkins, GitLab)
#
# Usage: ./clean-workspaces.sh
#

echo "============================================"
echo "  CI Runner Workspace Cleanup"
echo "  $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================"
echo ""

# ─── GitHub Actions Runner ───────────────────────────────────────────────────
GITHUB_WORK="$HOME/Tese/runners/github/_work"
if [ -d "$GITHUB_WORK" ]; then
    echo "🔵 GitHub Actions Runner"
    du -sh "$GITHUB_WORK" 2>/dev/null
    rm -rf "$GITHUB_WORK"/teseMestrado/
    rm -rf "$GITHUB_WORK"/_update/
    rm -rf "$GITHUB_WORK"/_temp/
    echo "   ✅ Cleaned"
else
    echo "🔵 GitHub Actions Runner — not found, skipping"
fi
echo ""

# ─── Azure DevOps Runner ────────────────────────────────────────────────────
AZURE_WORK="$HOME/Tese/runners/azure/_work"
if [ -d "$AZURE_WORK" ]; then
    echo "🟡 Azure DevOps Runner"
    du -sh "$AZURE_WORK" 2>/dev/null
    rm -rf "$AZURE_WORK"/[0-9]*/
    rm -rf "$AZURE_WORK"/_update/
    rm -rf "$AZURE_WORK"/_temp/
    echo "   ✅ Cleaned"
else
    echo "🟡 Azure DevOps Runner — not found, skipping"
fi
echo ""

# ─── Jenkins ─────────────────────────────────────────────────────────────────
JENKINS_WORK="$HOME/.jenkins/workspace"
if [ -d "$JENKINS_WORK" ]; then
    echo "🟠 Jenkins"
    du -sh "$JENKINS_WORK" 2>/dev/null
    rm -rf "$JENKINS_WORK"/*/
    echo "   ✅ Cleaned"
else
    echo "🟠 Jenkins — not found, skipping"
fi
echo ""

# ─── GitLab Runner ───────────────────────────────────────────────────────────
GITLAB_BUILDS="$HOME/Tese/teseMestradoGitlab/builds"
if [ -d "$GITLAB_BUILDS" ]; then
    echo "🟣 GitLab Runner"
    du -sh "$GITLAB_BUILDS" 2>/dev/null
    rm -rf "$GITLAB_BUILDS"/*/
    echo "   ✅ Cleaned"
else
    echo "🟣 GitLab Runner — not found, skipping"
fi
echo ""

# ─── Summary ─────────────────────────────────────────────────────────────────
echo "============================================"
echo "  Cleanup complete!"
echo "  Free disk space:"
df -h / | awk 'NR==2 {print "  " $4 " available"}'
echo "============================================"
