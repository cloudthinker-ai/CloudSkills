---
name: managing-puppeteer
description: |
  Puppeteer browser automation management and analysis. Covers test suite configuration, browser launch settings, page performance metrics, screenshot and PDF generation review, network interception analysis, and script debugging. Use when managing Puppeteer test suites, analyzing browser automation scripts, or reviewing headless Chrome configurations.
connection_type: puppeteer
preload: false
---

# Puppeteer Browser Automation Management Skill

Manage and analyze Puppeteer browser automation scripts and test suites.

## Core Helper Functions

```bash
#!/bin/bash

# Check Puppeteer installation and browser
puppeteer_info() {
    node -e "const p = require('puppeteer'); console.log(JSON.stringify({version: require('puppeteer/package.json').version, executablePath: p.executablePath()}))" 2>/dev/null
}
```

## MANDATORY: Discovery-First Pattern

**Always discover project configuration and test structure before querying specifics.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Puppeteer Installation ==="
node -e "console.log('Version:', require('puppeteer/package.json').version)" 2>/dev/null || echo "Puppeteer not installed"
node -e "const p = require('puppeteer'); console.log('Browser:', p.executablePath())" 2>/dev/null

echo ""
echo "=== Puppeteer Configuration ==="
if [ -f ".puppeteerrc.cjs" ]; then
    cat .puppeteerrc.cjs | head -20
elif [ -f ".puppeteerrc.js" ]; then
    cat .puppeteerrc.js | head -20
fi
grep -r "puppeteer" package.json 2>/dev/null | head -5

echo ""
echo "=== Test/Script Files ==="
find . -maxdepth 4 -name "*.puppeteer.*" -o -name "*puppet*test*" -o -name "*puppet*spec*" 2>/dev/null | head -15
find . -maxdepth 4 -name "*.e2e.*" 2>/dev/null | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Browser Launch Configurations ==="
grep -rn "puppeteer.launch" --include="*.js" --include="*.ts" -A 5 2>/dev/null | head -20

echo ""
echo "=== Page Navigation Patterns ==="
grep -rn "page.goto\|page.waitFor\|page.click\|page.type" --include="*.js" --include="*.ts" 2>/dev/null | wc -l | xargs echo "Total page interactions:"

echo ""
echo "=== Screenshot/PDF Generation ==="
grep -rn "page.screenshot\|page.pdf" --include="*.js" --include="*.ts" 2>/dev/null | head -10

echo ""
echo "=== Network Interception ==="
grep -rn "page.setRequestInterception\|page.on.*request\|page.on.*response" --include="*.js" --include="*.ts" 2>/dev/null | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target 50 lines per output
- Summarize script patterns rather than dumping full files
- Reference screenshot/PDF output paths, never embed binary content

## Anti-Hallucination Rules
- NEVER guess script file names — always discover via filesystem
- NEVER assume browser executable path — check actual Puppeteer config
- NEVER fabricate performance metrics — measure from actual runs

## Safety Rules
- NEVER execute Puppeteer scripts without user confirmation — they launch browsers
- NEVER modify automation scripts without user approval
- Be aware that headless browser execution can consume significant resources
