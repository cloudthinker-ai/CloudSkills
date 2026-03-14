---
name: security-code-review
enabled: true
description: |
  Security-focused code review template covering OWASP Top 10 vulnerabilities, injection attacks, authentication flaws, authorization bypass, sensitive data exposure, and cryptographic misuse. Provides a systematic security review framework for identifying and remediating security risks before code reaches production.
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

## Output Format

Produce a security review report with:
1. **Risk summary** (critical / high / medium / low findings)
2. **OWASP category mapping** for each finding
3. **Proof of concept** or exploitation scenario where applicable
4. **Remediation guidance** with code examples
5. **Compliance impact** (SOC2, PCI, HIPAA if relevant)
