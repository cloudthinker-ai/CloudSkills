---
name: open-source-contribution-review
enabled: true
description: |
  Use when performing open source contribution review — external open source
  contribution review template covering code quality standards, licensing
  compliance, security vetting, CLA verification, and community guidelines
  adherence. Provides a systematic framework for reviewing contributions from
  external contributors to ensure project quality, security, and legal
  compliance.
required_connections:
  - prefix: github
    label: "GitHub"
config_fields:
  - key: repository
    label: "Repository"
    required: true
    placeholder: "e.g., org/open-source-project"
  - key: pr_number
    label: "PR Number"
    required: true
    placeholder: "e.g., 1234"
  - key: project_license
    label: "Project License"
    required: false
    placeholder: "e.g., MIT, Apache-2.0, GPL-3.0"
features:
  - CODE_REVIEW
---

# Open Source Contribution Review Skill

Review external contribution PR **#{{ pr_number }}** in **{{ repository }}** ({{ project_license }}).

## Workflow

### Phase 1 — Contributor Verification

```
CONTRIBUTOR CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] CLA/DCO signed: YES / NO
[ ] Contributor profile reviewed:
    [ ] GitHub account age reasonable
    [ ] Previous contributions to other projects
    [ ] Not a known spam/malicious account
[ ] Contribution aligns with project roadmap: YES / NO
[ ] Related issue exists: YES / NO (issue #___)
[ ] Contribution discussed in advance: YES / NO
```

### Phase 2 — Code Quality

```
QUALITY STANDARDS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Code style:
    [ ] Follows project coding standards
    [ ] Linting passes (no new warnings)
    [ ] Consistent with existing codebase patterns
[ ] Documentation:
    [ ] Public APIs documented
    [ ] README updated for new features
    [ ] Inline comments for complex logic
    [ ] CHANGELOG entry added
[ ] Testing:
    [ ] Tests provided for new functionality
    [ ] Existing tests still pass
    [ ] Edge cases covered
    [ ] Test coverage maintained or improved
[ ] Scope:
    [ ] Single concern (not mixing features/fixes)
    [ ] Appropriate PR size
    [ ] No unnecessary refactoring bundled
```

### Phase 3 — Security Vetting

```
SECURITY REVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Malicious code check:
    [ ] No obfuscated code
    [ ] No unexpected network calls
    [ ] No data exfiltration patterns
    [ ] No cryptocurrency mining code
    [ ] No backdoors or hidden functionality
[ ] Dependency safety:
    [ ] New dependencies justified and vetted
    [ ] No typosquatting packages
    [ ] Dependencies from trusted sources
    [ ] No unnecessary transitive dependencies
[ ] Input handling:
    [ ] User input validated and sanitized
    [ ] No command injection vectors
    [ ] File operations are safe (no path traversal)
```

### Phase 4 — Licensing

```
LICENSE COMPLIANCE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Contribution compatible with project license ({{ project_license }}): YES / NO
[ ] No copy-pasted code from incompatible licenses: YES / NO
[ ] New dependencies license-compatible:
    Package          | License    | Compatible
    ─────────────────┼────────────┼───────────
    ___              | ___        | YES / NO
[ ] Copyright headers present where required: YES / NO
[ ] Third-party attribution updated: YES / NO
```

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format

Produce a contribution review report with:
1. **Contributor verification** status
2. **Code quality** assessment (meets standards / needs work)
3. **Security findings** (clean / concerns found)
4. **License compliance** (compatible / incompatible / needs review)
5. **Recommendation** (accept / accept with changes / reject with reason)
