---
name: tech-radar-update
enabled: true
description: |
  Use when performing tech radar update — guides the process of creating or
  updating a technology radar that tracks the adoption status of technologies,
  tools, frameworks, and practices across the organization. Covers technology
  assessment, ring classification, team input collection, and communication of
  technology guidance.
required_connections:
  - prefix: wiki
    label: "Documentation Platform"
config_fields:
  - key: organization_name
    label: "Organization Name"
    required: true
    placeholder: "e.g., Acme Corp Engineering"
  - key: radar_scope
    label: "Radar Scope"
    required: true
    placeholder: "e.g., full stack, backend only, infrastructure"
  - key: update_frequency
    label: "Update Frequency"
    required: false
    placeholder: "e.g., quarterly, semi-annually"
features:
  - TEAM_PRODUCTIVITY
  - TECHNOLOGY
  - STRATEGY
---

# Tech Radar Update

## Phase 1: Input Collection
1. Gather technology nominations from teams
   - [ ] New technologies teams want to adopt
   - [ ] Technologies teams have been experimenting with
   - [ ] Technologies that should be reconsidered (deprecated, security concerns)
   - [ ] Technologies teams want to standardize on
   - [ ] Pain points with current technology choices
2. Review industry trends and analyst reports
3. Collect feedback from architecture review board
4. Review incident reports for technology-related issues

### Technology Nomination Form

| Technology | Category | Nominated By | Current Usage | Proposal | Justification |
|-----------|----------|-------------|---------------|----------|---------------|
|           | Languages/Frameworks/Tools/Platforms/Techniques | | None/Trial/Some/Wide | Adopt/Trial/Assess/Hold | |

## Phase 2: Technology Assessment
1. Evaluate each nominated technology
   - [ ] Technical maturity and community support
   - [ ] Fit with existing architecture and stack
   - [ ] Learning curve and team expertise
   - [ ] Security posture and vulnerability history
   - [ ] License compatibility
   - [ ] Performance characteristics
   - [ ] Operational complexity
   - [ ] Vendor lock-in risk
   - [ ] Total cost of ownership
2. Gather input from teams with experience

### Assessment Criteria Matrix

| Technology | Maturity | Fit | Learning Curve | Security | License | Ops Complexity | Score |
|-----------|---------|-----|---------------|----------|---------|---------------|-------|
|           | 1-5     | 1-5 | 1-5           | 1-5      | OK/Risk | 1-5           | /30   |

## Phase 3: Ring Classification
1. Classify each technology into a ring

### Ring Definitions

| Ring | Meaning | Guidance | Example Criteria |
|------|---------|----------|-----------------|
| **Adopt** | Proven, recommended for broad use | Teams should use this | Mature, well-supported, team expertise exists |
| **Trial** | Worth pursuing, proven in limited use | Teams may use with architecture review | Promising, some production experience |
| **Assess** | Worth exploring, understand impact | Research and prototype only | Interesting, needs evaluation |
| **Hold** | Proceed with caution, do not start new | Existing uses OK, no new adoption | Deprecated, security concern, better alternative exists |

## Phase 4: Radar Organization by Quadrant

### Languages & Frameworks

| Technology | Previous Ring | Current Ring | Change | Notes |
|-----------|-------------|-------------|--------|-------|
|           |             |             | New/Moved/Unchanged | |

### Tools

| Technology | Previous Ring | Current Ring | Change | Notes |
|-----------|-------------|-------------|--------|-------|
|           |             |             | New/Moved/Unchanged | |

### Platforms & Infrastructure

| Technology | Previous Ring | Current Ring | Change | Notes |
|-----------|-------------|-------------|--------|-------|
|           |             |             | New/Moved/Unchanged | |

### Techniques & Practices

| Technology | Previous Ring | Current Ring | Change | Notes |
|-----------|-------------|-------------|--------|-------|
|           |             |             | New/Moved/Unchanged | |

## Phase 5: Documentation & Rationale
1. Document each technology entry
   - [ ] Brief description of the technology
   - [ ] Why it is in its current ring
   - [ ] What changed since last update (if applicable)
   - [ ] Recommended alternatives (for Hold items)
   - [ ] Links to internal experience reports or POC results
   - [ ] Contact person or team for questions
2. Write summary of key changes from previous radar

### Key Changes Summary

| Change Type | Count | Notable Examples |
|------------|-------|-----------------|
| New entries | | |
| Moved to Adopt | | |
| Moved to Hold | | |
| Removed | | |

## Phase 6: Communication & Adoption
1. Publish and communicate the updated radar
   - [ ] Publish radar visualization (interactive if possible)
   - [ ] Write blog post or newsletter summarizing changes
   - [ ] Present at engineering all-hands or tech talk
   - [ ] Update architecture decision records as needed
   - [ ] Notify teams affected by Hold recommendations
   - [ ] Plan migration support for Hold technologies
2. Schedule next radar update cycle

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format
- **Tech Radar Visualization**: Interactive radar with all quadrants and rings
- **Technology Profiles**: Detailed write-up per technology entry
- **Change Summary**: What moved and why since last update
- **Migration Guides**: Plans for technologies moved to Hold
- **Next Review Date**: Scheduled date for next update cycle

## Action Items
- [ ] Collect technology nominations from all teams
- [ ] Assess each nomination against evaluation criteria
- [ ] Classify technologies into rings with architecture review board
- [ ] Document rationale for each classification
- [ ] Publish updated radar and communicate changes
- [ ] Create migration plans for newly Hold technologies
- [ ] Schedule next radar update cycle
