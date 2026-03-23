---
name: meeting-effectiveness-review
enabled: true
description: |
  Use when performing meeting effectiveness review — conducts a review of team
  meeting practices to identify waste, improve effectiveness, and reclaim
  productive time. Covers meeting inventory, cost analysis, attendee
  optimization, agenda quality, decision tracking, and implementation of meeting
  hygiene practices across the organization.
required_connections:
  - prefix: calendar
    label: "Calendar Platform"
config_fields:
  - key: team_name
    label: "Team or Organization Name"
    required: true
    placeholder: "e.g., Engineering Department"
  - key: team_size
    label: "Team Size"
    required: true
    placeholder: "e.g., 40 people"
  - key: review_period
    label: "Review Period"
    required: false
    placeholder: "e.g., last 4 weeks"
features:
  - TEAM_PRODUCTIVITY
  - MEETINGS
  - PROCESS
---

# Meeting Effectiveness Review

## Phase 1: Meeting Inventory
1. Catalog all recurring meetings
   - [ ] Meeting name and purpose
   - [ ] Frequency and duration
   - [ ] Number of attendees
   - [ ] Organizer and owner
   - [ ] Whether it has an agenda
   - [ ] Whether it produces action items
2. Calculate meeting load per person
3. Identify meeting-free blocks availability

### Meeting Inventory

| Meeting | Frequency | Duration | Attendees | Has Agenda | Has Actions | Cost/Year |
|---------|-----------|----------|-----------|-----------|------------|-----------|
|         | weekly    | min      |           | Yes/No    | Yes/No     | $         |

## Phase 2: Meeting Cost Analysis
1. Calculate meeting costs (attendee hours * avg hourly rate)
2. Identify most expensive meetings
3. Calculate total meeting hours per person per week
4. Compare meeting time vs. focus time ratio

### Team Meeting Load

| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| Avg meeting hours/person/week | hrs | < 12 hrs | |
| Meeting-free blocks/week | | > 3 (2hr+) | |
| Recurring meetings count | | < | |
| Total annual meeting cost | $ | $ | |
| Focus time ratio | % | > 50% | |

## Phase 3: Effectiveness Assessment
1. Evaluate each meeting against effectiveness criteria
   - [ ] Clear purpose and desired outcome defined
   - [ ] Agenda shared in advance
   - [ ] Right attendees (decision makers, contributors, informed)
   - [ ] Starts and ends on time
   - [ ] Action items captured with owners and deadlines
   - [ ] Follow-up on previous action items
   - [ ] Could be replaced by async communication
2. Survey participants on meeting value

### Meeting Effectiveness Scorecard

| Meeting | Purpose Clear | Agenda | Right People | On Time | Actions | Value Score (1-5) | Recommendation |
|---------|-------------|--------|-------------|---------|---------|------------------|----------------|
|         | [ ]         | [ ]    | [ ]         | [ ]     | [ ]     |                  | Keep/Improve/Cut |

## Phase 4: Decision Matrix for Each Meeting

### Recommendation Categories

| Category | Criteria | Action |
|----------|----------|--------|
| Keep as-is | High value, well-run, right people | No changes needed |
| Optimize | Valuable purpose but poor execution | Fix agenda, attendees, duration |
| Reduce | Too frequent for content generated | Reduce frequency or duration |
| Merge | Overlapping purpose with another meeting | Combine into single meeting |
| Replace | Could be async (status updates, FYI) | Move to Slack/email/doc |
| Eliminate | No clear purpose, low attendance value | Cancel the meeting |

### Recommendations Summary

| Action | Meeting Count | Hours Saved/Week | Annual Cost Saved |
|--------|-------------|-----------------|-------------------|
| Keep | | 0 | $0 |
| Optimize | | hrs | $ |
| Reduce | | hrs | $ |
| Merge | | hrs | $ |
| Replace with async | | hrs | $ |
| Eliminate | | hrs | $ |
| **Total** | | **hrs** | **$** |

## Phase 5: Meeting Hygiene Standards
1. Establish meeting best practices
   - [ ] All meetings must have a purpose statement
   - [ ] Agenda required 24 hours before meeting
   - [ ] Default to 25min or 50min (not 30/60) for transition time
   - [ ] Attendance is optional unless marked required
   - [ ] No-agenda-no-meeting policy
   - [ ] Meeting-free days or blocks (e.g., no meetings Wednesday)
   - [ ] Action items documented within 24 hours
   - [ ] Quarterly meeting audit to prune calendar
2. Communicate standards to all teams

## Phase 6: Implementation & Tracking
1. Execute meeting changes
   - [ ] Cancel eliminated meetings
   - [ ] Reduce frequency of identified meetings
   - [ ] Merge overlapping meetings
   - [ ] Set up async alternatives for replaced meetings
   - [ ] Publish meeting hygiene guidelines
2. Track improvements over time

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format
- **Meeting Inventory**: Complete catalog with cost analysis
- **Effectiveness Scores**: Per-meeting evaluation results
- **Recommendations**: Categorized actions per meeting
- **Meeting Guidelines**: Published best practices document
- **Impact Report**: Hours and costs saved

## Action Items
- [ ] Complete meeting inventory and cost analysis
- [ ] Score each meeting for effectiveness
- [ ] Apply decision matrix and generate recommendations
- [ ] Get team agreement on meetings to change
- [ ] Implement changes (cancel, reduce, merge, async)
- [ ] Publish meeting hygiene standards
- [ ] Schedule quarterly meeting audit
