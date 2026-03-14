---
name: pen-test-planning
enabled: true
description: |
  Plans and scopes a penetration test engagement, covering target identification, rules of engagement, testing methodology selection, team coordination, communication protocols, and findings remediation workflow. Supports network, application, cloud, and social engineering test types.
required_connections:
  - prefix: security-tools
    label: "Security Testing Tools"
config_fields:
  - key: test_type
    label: "Penetration Test Type"
    required: true
    placeholder: "e.g., external network, web application, cloud, internal"
  - key: target_systems
    label: "Target Systems or Applications"
    required: true
    placeholder: "e.g., public web app, internal network 10.0.0.0/16, AWS account"
  - key: engagement_type
    label: "Engagement Type"
    required: false
    placeholder: "e.g., black box, gray box, white box"
features:
  - COMPLIANCE
  - SECURITY
  - PENETRATION_TESTING
---

# Penetration Test Planning

## Phase 1: Scope & Objectives
1. Define test objectives
   - [ ] Identify vulnerabilities in target systems
   - [ ] Validate effectiveness of security controls
   - [ ] Meet compliance requirements (PCI DSS, SOC 2, etc.)
   - [ ] Test incident response capabilities
   - [ ] Assess lateral movement potential
2. Define in-scope targets
   - [ ] IP ranges and hostnames
   - [ ] Web applications and APIs
   - [ ] Cloud accounts and services
   - [ ] Mobile applications
   - [ ] Wireless networks
3. Define out-of-scope exclusions
4. Set testing window and timeline

### Scope Summary

| Target | Type | Environment | Testing Method | Priority |
|--------|------|-------------|---------------|----------|
|        | Network/App/Cloud/Wireless | Prod/Staging | Black/Gray/White box | High/Med/Low |

## Phase 2: Rules of Engagement
1. Define rules of engagement
   - [ ] Testing hours and days permitted
   - [ ] Acceptable attack techniques
   - [ ] Prohibited actions (DoS, data destruction, social engineering limits)
   - [ ] Data handling for sensitive findings
   - [ ] Escalation procedures for critical findings
   - [ ] Emergency stop procedures and contacts
2. Get written authorization from system owners
3. Coordinate with SOC/monitoring team
4. Establish communication channels

### Emergency Contact Matrix

| Role | Name | Phone | Email | When to Contact |
|------|------|-------|-------|-----------------|
| Test Lead | | | | Test coordination |
| System Owner | | | | Authorization issues |
| SOC Contact | | | | Alert deconfliction |
| Emergency Stop | | | | Critical system impact |

## Phase 3: Methodology Selection
1. Select testing methodology
   - [ ] OWASP Testing Guide (web applications)
   - [ ] PTES (Penetration Testing Execution Standard)
   - [ ] NIST SP 800-115 (Technical Guide to Testing)
   - [ ] OSSTMM (Open Source Security Testing Methodology)
   - [ ] Cloud-specific (AWS/GCP/Azure testing guides)
2. Define testing phases
   - Reconnaissance and information gathering
   - Vulnerability scanning and analysis
   - Exploitation and validation
   - Post-exploitation and lateral movement
   - Reporting and remediation support

## Phase 4: Tool & Resource Preparation
1. Prepare testing environment and tools
   - [ ] Network scanning (Nmap, Masscan)
   - [ ] Vulnerability scanning (Nessus, Qualys)
   - [ ] Web application testing (Burp Suite, OWASP ZAP)
   - [ ] Exploitation frameworks (Metasploit, custom scripts)
   - [ ] Cloud assessment tools (ScoutSuite, Prowler)
   - [ ] Password testing (Hashcat, John the Ripper)
   - [ ] Reporting templates
2. Set up VPN access and testing accounts (gray/white box)
3. Verify testing infrastructure is ready

## Phase 5: Execution Plan
1. Day-by-day execution schedule
   - Day 1-2: Reconnaissance and scanning
   - Day 3-5: Vulnerability analysis and exploitation
   - Day 6-7: Post-exploitation and lateral movement
   - Day 8: Cleanup and evidence collection
   - Day 9-10: Report writing
2. Daily status reporting to stakeholders
3. Immediate notification for critical findings
4. Evidence collection and chain of custody

## Phase 6: Reporting & Remediation
1. Prepare penetration test report
   - Executive summary for leadership
   - Technical findings with CVSS scoring
   - Proof-of-concept details with evidence
   - Remediation recommendations prioritized by risk
   - Positive findings (controls that worked)
2. Conduct findings walkthrough with technical team
3. Develop remediation plan with timelines
4. Schedule retest for critical and high findings

### Finding Severity Classification

| Severity | CVSS Score | Remediation SLA | Example |
|----------|-----------|-----------------|---------|
| Critical | 9.0-10.0 | 7 days | RCE, auth bypass |
| High | 7.0-8.9 | 30 days | SQLi, privilege escalation |
| Medium | 4.0-6.9 | 90 days | XSS, info disclosure |
| Low | 0.1-3.9 | 180 days | Missing headers, verbose errors |

## Output Format
- **Scope Document**: Targets, rules of engagement, authorization
- **Test Plan**: Day-by-day schedule with methodology
- **Status Reports**: Daily updates during testing
- **Final Report**: Executive summary and technical findings
- **Remediation Tracker**: Findings with owners and SLA deadlines

## Action Items
- [ ] Define scope and get written authorization
- [ ] Establish rules of engagement and emergency contacts
- [ ] Coordinate with SOC to avoid false positive alerts
- [ ] Prepare tools and testing environment
- [ ] Execute test per approved schedule
- [ ] Deliver report and conduct findings walkthrough
- [ ] Track remediation to completion and schedule retest
