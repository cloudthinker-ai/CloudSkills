---
name: security-code-review
enabled: true
description: |
  Use when performing security code review — security-focused code review
  template covering OWASP Top 10 vulnerabilities, injection attacks,
  authentication flaws, authorization bypass, sensitive data exposure, and
  cryptographic misuse. Provides a systematic security review framework for
  identifying and remediating security risks before code reaches production.
required_connections:
  - prefix: github
    label: "GitHub"
config_fields:
  - key: repository
    label: "Repository"
    required: true
    placeholder: "e.g., org/backend-service"
  - key: pr_number
    label: "PR Number"
    required: true
    placeholder: "e.g., 1234"
  - key: threat_model
    label: "Threat Model Reference"
    required: false
    placeholder: "e.g., STRIDE analysis doc link"
features:
  - CODE_REVIEW
---

# Security Code Review Skill

Security review of PR **#{{ pr_number }}** in **{{ repository }}**.

## Workflow

### Phase 1 — Injection Vulnerabilities

```
INJECTION REVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] SQL Injection:
    [ ] Parameterized queries used (no string concatenation)
    [ ] ORM queries reviewed for raw SQL usage
    [ ] Stored procedures use parameters
[ ] Command Injection:
    [ ] No user input in shell commands
    [ ] subprocess/exec calls use argument lists
    [ ] Input sanitized before system calls
[ ] LDAP/XPath/NoSQL Injection:
    [ ] Query parameters properly escaped
    [ ] No dynamic query construction with user input
[ ] Template Injection:
    [ ] Server-side templates sanitize variables
    [ ] No user-controlled template strings
```

### Phase 2 — Authentication and Authorization

```
AUTH REVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Authentication:
    [ ] Password hashing uses bcrypt/argon2 (not MD5/SHA1)
    [ ] Multi-factor authentication supported
    [ ] Session management is secure (HTTPOnly, Secure flags)
    [ ] Token expiration enforced
    [ ] Brute force protection (rate limiting, lockout)
[ ] Authorization:
    [ ] Every endpoint has authorization check
    [ ] RBAC/ABAC enforced consistently
    [ ] No privilege escalation paths
    [ ] IDOR (Insecure Direct Object Reference) prevented
    [ ] Horizontal privilege escalation checked
```

### Phase 3 — Sensitive Data

```
DATA PROTECTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] No secrets in source code (API keys, passwords, tokens)
[ ] Sensitive data encrypted at rest
[ ] TLS enforced for data in transit
[ ] PII properly handled and masked in logs
[ ] Cryptographic algorithms are current (no DES, MD5, SHA1)
[ ] Key management follows best practices
[ ] Sensitive data not cached client-side
```

### Phase 4 — Cross-Site Scripting (XSS)

```
XSS REVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Output encoding applied for all user-generated content
[ ] Content Security Policy (CSP) headers configured
[ ] DOM manipulation sanitizes input
[ ] React/Angular/Vue: dangerouslySetInnerHTML avoided
[ ] URL parameters validated before rendering
[ ] SVG/HTML file uploads sanitized
```

### Phase 5 — Security Misconfiguration

```
CONFIGURATION REVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Debug mode disabled in production config
[ ] Error messages do not leak stack traces
[ ] CORS policy is restrictive (no wildcard origins)
[ ] Security headers set (X-Frame-Options, HSTS, etc.)
[ ] Default credentials changed
[ ] Unnecessary features/endpoints disabled
[ ] Dependencies scanned for known CVEs
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

Produce a security review report with:
1. **Risk summary** (critical / high / medium / low findings)
2. **OWASP category mapping** for each finding
3. **Proof of concept** or exploitation scenario where applicable
4. **Remediation guidance** with code examples
5. **Compliance impact** (SOC2, PCI, HIPAA if relevant)
