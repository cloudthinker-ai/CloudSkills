---
name: managing-sonarqube
description: |
  SonarQube code quality management. Covers project analysis, quality gate status, issue tracking, code coverage metrics, technical debt analysis, and quality profile configuration. Use when managing SonarQube projects, reviewing quality gates, analyzing code smells, or tracking technical debt.
connection_type: sonarqube
preload: false
---

# SonarQube Code Quality Management Skill

Manage and analyze SonarQube projects, quality gates, issues, and code metrics.

## MANDATORY: Discovery-First Pattern

**Always check current SonarQube project configuration before modifying quality settings.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== SonarQube Configuration ==="
cat sonar-project.properties 2>/dev/null | head -15

echo ""
echo "=== Project Status ==="
curl -s -u "${SONAR_TOKEN}:" "${SONAR_URL}/api/qualitygates/project_status?projectKey=${SONAR_PROJECT}" 2>/dev/null | jq '{
  status: .projectStatus.status,
  conditions: [.projectStatus.conditions[] | {
    metric: .metricKey,
    status: .status,
    value: .actualValue,
    threshold: .errorThreshold
  }]
}' 2>/dev/null

echo ""
echo "=== Server Version ==="
curl -s "${SONAR_URL}/api/system/status" 2>/dev/null | jq '.version' 2>/dev/null
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Project Metrics ==="
curl -s -u "${SONAR_TOKEN}:" "${SONAR_URL}/api/measures/component?component=${SONAR_PROJECT}&metricKeys=bugs,vulnerabilities,code_smells,coverage,duplicated_lines_density,ncloc,sqale_debt_ratio" 2>/dev/null | jq '{
  metrics: [.component.measures[] | {
    metric: .metric,
    value: .value
  }]
}' 2>/dev/null

echo ""
echo "=== Open Issues by Severity ==="
curl -s -u "${SONAR_TOKEN}:" "${SONAR_URL}/api/issues/search?componentKeys=${SONAR_PROJECT}&resolved=false&facets=severities&ps=1" 2>/dev/null | jq '{
  total: .total,
  by_severity: [.facets[0].values[] | {severity: .val, count: .count}]
}' 2>/dev/null
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Summarize quality gate status with pass/fail conditions
- Group issues by severity and type
- Report coverage and duplication as percentages

## Common Operations

### Issue Analysis

```bash
#!/bin/bash
echo "=== Top Issues ==="
curl -s -u "${SONAR_TOKEN}:" "${SONAR_URL}/api/issues/search?componentKeys=${SONAR_PROJECT}&resolved=false&s=SEVERITY&asc=false&ps=10" 2>/dev/null | jq '[.issues[] | {
  key: .key,
  severity: .severity,
  type: .type,
  message: .message[:80],
  component: .component
}]' 2>/dev/null
```

### Quality Profile

```bash
#!/bin/bash
echo "=== Quality Profile ==="
curl -s -u "${SONAR_TOKEN}:" "${SONAR_URL}/api/qualityprofiles/search?project=${SONAR_PROJECT}" 2>/dev/null | jq '[.profiles[] | {
  name: .name,
  language: .language,
  activeRuleCount: .activeRuleCount,
  isDefault: .isDefault
}]' 2>/dev/null
```

## Safety Rules

- **Never lower quality gate thresholds** without team consensus
- **Review new rule activations** before applying to production profiles
- **SonarQube tokens** must be stored in CI secrets, never in project files
- **Monitor false positive rates** -- excessive false positives erode developer trust
