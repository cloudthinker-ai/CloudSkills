---
name: sox-it-controls-audit
enabled: true
description: |
  Use when performing sox it controls audit — conducts an IT general controls
  audit for Sarbanes-Oxley (SOX) compliance, covering access management, change
  management, computer operations, and program development controls for systems
  involved in financial reporting. Includes ITGC testing procedures and
  deficiency classification.
required_connections:
  - prefix: grc-tool
    label: "GRC Platform"
config_fields:
  - key: organization_name
    label: "Organization Name"
    required: true
    placeholder: "e.g., Acme Corp"
  - key: fiscal_year
    label: "Fiscal Year Under Audit"
    required: true
    placeholder: "e.g., FY2026"
  - key: in_scope_systems
    label: "In-Scope Financial Systems"
    required: true
    placeholder: "e.g., SAP, Oracle EBS, NetSuite, custom billing"
features:
  - COMPLIANCE
  - SOX
  - AUDIT
---

# SOX IT Controls Audit

## Phase 1: Scope Definition
1. Identify in-scope systems for financial reporting
   - [ ] ERP / financial accounting systems
   - [ ] Billing and revenue systems
   - [ ] Payroll systems
   - [ ] Reporting and consolidation tools
   - [ ] Supporting infrastructure (databases, OS, network)
   - [ ] Cloud platforms hosting financial applications
2. Map IT dependencies for each material business process
3. Define control objectives per system
4. Identify key reports and interfaces

### System Scoping Matrix

| System | Business Process | Material Account | ITGC Categories | Risk Rating |
|--------|-----------------|------------------|----------------|-------------|
|        |                 |                  | AC/CM/CO/PD    | High/Med/Low |

## Phase 2: Access Control Testing (AC)
1. Test logical access controls
   - [ ] AC-1: New user access provisioning follows approval process
   - [ ] AC-2: User access is based on role/job function (least privilege)
   - [ ] AC-3: Terminated users removed within defined timeframe
   - [ ] AC-4: Periodic access reviews performed (quarterly/semi-annually)
   - [ ] AC-5: Privileged/admin access restricted and monitored
   - [ ] AC-6: Password policies enforce complexity and rotation
   - [ ] AC-7: Segregation of duties enforced in financial systems
   - [ ] AC-8: Service accounts managed and reviewed
2. Sample and test user provisioning and deprovisioning
3. Review privileged access logs
4. Test segregation of duties conflicts

## Phase 3: Change Management Testing (CM)
1. Test change management controls
   - [ ] CM-1: Changes follow documented approval process
   - [ ] CM-2: Changes tested before production deployment
   - [ ] CM-3: Separation of development and production environments
   - [ ] CM-4: Emergency changes follow expedited approval process
   - [ ] CM-5: Developer access to production restricted
   - [ ] CM-6: Changes to databases and infrastructure follow process
   - [ ] CM-7: Version control and rollback procedures exist
2. Sample and test change records for proper approvals
3. Verify test evidence for sampled changes
4. Review emergency change documentation

## Phase 4: Computer Operations Testing (CO)
1. Test IT operations controls
   - [ ] CO-1: Batch jobs/scheduled tasks monitored for completion
   - [ ] CO-2: Job failures investigated and resolved timely
   - [ ] CO-3: Data backups performed per schedule
   - [ ] CO-4: Backup restoration tested periodically
   - [ ] CO-5: Incident management process followed
   - [ ] CO-6: System availability monitored against SLAs
   - [ ] CO-7: Physical/environmental controls adequate
2. Review batch job monitoring logs
3. Verify backup and restoration test evidence
4. Review incident records for operational issues

## Phase 5: Program Development Testing (PD)
1. Test program development controls
   - [ ] PD-1: SDLC methodology documented and followed
   - [ ] PD-2: Requirements documented and approved
   - [ ] PD-3: User acceptance testing performed
   - [ ] PD-4: Data migration validated for system implementations
   - [ ] PD-5: Post-implementation review completed
2. Sample and test new system implementations
3. Verify project documentation and approvals

### Control Testing Summary

| Category | Controls Tested | Effective | Deficiency | Material Weakness |
|----------|----------------|-----------|------------|-------------------|
| Access Controls (AC) | | | | |
| Change Management (CM) | | | | |
| Computer Operations (CO) | | | | |
| Program Development (PD) | | | | |
| **Total** | | | | |

## Phase 6: Deficiency Assessment & Reporting
1. Classify identified deficiencies
   - Control deficiency: control does not operate effectively
   - Significant deficiency: reasonable possibility of material misstatement not prevented
   - Material weakness: reasonable possibility of material misstatement not prevented or detected
2. Develop remediation recommendations
3. Prepare management response for each finding
4. Report to audit committee

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format
- **Scoping Document**: In-scope systems and control objectives
- **Test Work Papers**: Evidence and results per control
- **Deficiency Report**: Classified findings with root cause
- **Remediation Plan**: Corrective actions with owners and deadlines
- **Management Letter**: Summary of findings for leadership

## Action Items
- [ ] Finalize system scoping with external auditors
- [ ] Complete access control testing for all in-scope systems
- [ ] Test change management sample for the audit period
- [ ] Verify computer operations controls and evidence
- [ ] Classify all deficiencies found
- [ ] Develop remediation plans for each deficiency
- [ ] Present findings to audit committee
