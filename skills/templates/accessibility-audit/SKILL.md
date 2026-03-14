---
name: accessibility-audit
enabled: true
description: |
  Comprehensive accessibility audit template following WCAG 2.1 guidelines. Covers automated scanning, manual testing, keyboard navigation, screen reader compatibility, color contrast analysis, and remediation planning to ensure digital products are usable by people with disabilities.
required_connections:
  - prefix: github
    label: "GitHub"
config_fields:
  - key: application_name
    label: "Application Name"
    required: true
    placeholder: "e.g., customer-portal"
  - key: wcag_level
    label: "Target WCAG Level"
    required: true
    placeholder: "e.g., AA, AAA"
  - key: pages_to_audit
    label: "Pages/Views to Audit"
    required: false
    placeholder: "e.g., homepage, checkout, dashboard"
features:
  - ENGINEERING
  - ACCESSIBILITY
---

# Accessibility Audit Skill

Audit **{{ application_name }}** for WCAG 2.1 **Level {{ wcag_level }}** compliance.

## Workflow

### Phase 1 — Automated Scanning

```
AUTOMATED AUDIT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Tools used:
    [ ] axe-core / axe DevTools
    [ ] WAVE
    [ ] Lighthouse accessibility audit
    [ ] Pa11y
[ ] Pages scanned: {{ pages_to_audit }}
[ ] Results summary:
    - Critical violations: ___
    - Serious violations: ___
    - Moderate violations: ___
    - Minor violations: ___
    - Total issues: ___
```

### Phase 2 — Perceivable (WCAG Principle 1)

```
PERCEIVABLE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1.1 Text Alternatives:
[ ] All images have meaningful alt text
[ ] Decorative images use alt="" or CSS background
[ ] Complex images have extended descriptions
[ ] Icons have accessible labels

1.2 Time-Based Media:
[ ] Video has captions
[ ] Audio has transcripts
[ ] Live content has real-time captions (if applicable)

1.3 Adaptable:
[ ] Semantic HTML used (headings, landmarks, lists)
[ ] Heading hierarchy is logical (h1 -> h2 -> h3)
[ ] Tables have proper headers (th, scope, caption)
[ ] Form fields have associated labels
[ ] Reading order is logical when CSS is disabled

1.4 Distinguishable:
[ ] Color contrast ratios meet {{ wcag_level }}:
    - Normal text: ___ :1 (min 4.5:1 for AA)
    - Large text: ___ :1 (min 3:1 for AA)
[ ] Color is not the sole conveyor of information
[ ] Text can be resized to 200% without loss
[ ] Content reflows at 320px viewport width
```

### Phase 3 — Operable (WCAG Principle 2)

```
OPERABLE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
2.1 Keyboard Accessible:
[ ] All interactive elements reachable via Tab
[ ] Focus order is logical
[ ] No keyboard traps
[ ] Custom components have keyboard support
[ ] Skip navigation link present

2.2 Enough Time:
[ ] Timeouts can be extended or disabled
[ ] Auto-updating content can be paused
[ ] No content flashes more than 3 times/second

2.4 Navigable:
[ ] Page titles are descriptive and unique
[ ] Focus is visible on all interactive elements
[ ] Link text is descriptive (no "click here")
[ ] Multiple navigation methods available
[ ] Breadcrumbs or site map provided
```

### Phase 4 — Understandable (WCAG Principle 3)

```
UNDERSTANDABLE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
3.1 Readable:
[ ] Page language declared (lang attribute)
[ ] Content language changes indicated
[ ] Reading level appropriate for audience

3.2 Predictable:
[ ] Navigation is consistent across pages
[ ] Components behave consistently
[ ] No unexpected context changes on focus/input

3.3 Input Assistance:
[ ] Form errors clearly identified
[ ] Error messages are descriptive
[ ] Required fields indicated
[ ] Input format hints provided
[ ] Confirmation for irreversible actions
```

### Phase 5 — Screen Reader Testing

```
SCREEN READER TESTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Tested with:
    [ ] VoiceOver (macOS/iOS)
    [ ] NVDA (Windows)
    [ ] JAWS (Windows)
[ ] Key user journeys tested:
    [ ] ___  — PASS / FAIL
    [ ] ___  — PASS / FAIL
    [ ] ___  — PASS / FAIL
[ ] ARIA attributes used correctly
[ ] Live regions announce dynamic content
[ ] Modal dialogs trap focus appropriately
```

### Phase 6 — Remediation Plan

```
REMEDIATION PRIORITY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Priority | Issue                  | WCAG Criterion | Effort
CRITICAL | ___                    | ___            | ___
HIGH     | ___                    | ___            | ___
MEDIUM   | ___                    | ___            | ___
LOW      | ___                    | ___            | ___

Estimated total remediation effort: ___
Target completion date: ___
```

## Output Format

Produce an accessibility audit report with:
1. **Compliance summary** (overall score, level achieved)
2. **Violations by WCAG principle** (perceivable, operable, understandable, robust)
3. **Screen reader test results** (pass/fail by user journey)
4. **Remediation plan** (prioritized issues with effort estimates)
5. **Recommendations** (process improvements, tooling, training)
