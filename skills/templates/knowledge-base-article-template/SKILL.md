---
name: knowledge-base-article-template
enabled: true
description: |
  Template for writing IT support knowledge base articles covering problem description, step-by-step resolution, troubleshooting tips, and related resources. Provides a standardized format for documenting solutions so helpdesk agents and end users can find and follow resolutions consistently.
required_connections:
  - prefix: itsm
    label: "ITSM Tool (ServiceNow, Freshservice, etc.)"
config_fields:
  - key: article_title
    label: "Article Title"
    required: true
    placeholder: "e.g., How to Connect to Corporate VPN on macOS"
  - key: category
    label: "Category"
    required: true
    placeholder: "e.g., Network, Email, Software, Hardware, Access"
  - key: audience
    label: "Target Audience"
    required: true
    placeholder: "e.g., End Users, Helpdesk Agents, IT Admins"
  - key: related_tickets
    label: "Related Ticket IDs (for reference)"
    required: false
    placeholder: "e.g., INC-1234, INC-5678"
features:
  - HELPDESK
---

# Knowledge Base Article Template

## Article Metadata

```
ARTICLE DETAILS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Title:           {{ article_title }}
Category:        {{ category }}
Audience:        {{ audience }}
Related Tickets: {{ related_tickets }}
Author:          [author name]
Created:         [date]
Last Updated:    [date]
Review Date:     [date + 6 months]
Status:          [ ] Draft / [ ] In Review / [ ] Published
```

## Article Structure

Use the following standardized structure for all KB articles:

---

### {{ article_title }}

**Category:** {{ category }} | **Audience:** {{ audience }}

#### Applies To
- [List the systems, applications, or hardware this article applies to]
- [Include version numbers where relevant]
- [Specify operating systems if applicable]

#### Symptoms / Problem Description
Describe the issue the user is experiencing in clear, non-technical language (if audience is end users):

- [Symptom 1 — what the user sees or experiences]
- [Symptom 2 — error messages, if any, in exact wording]
- [Symptom 3 — when/how the issue typically occurs]

#### Cause
Brief explanation of why this issue occurs (optional for end-user articles, recommended for agent/admin articles):

- [Root cause or common trigger]

#### Resolution

**Step-by-step instructions:**

1. **[Action verb] [what to do]**
   - [Detailed sub-step if needed]
   - [Include screenshot placeholder: `[Screenshot: description]`]

2. **[Action verb] [what to do]**
   - [Detailed sub-step]
   - Expected result: [what should happen]

3. **[Action verb] [what to do]**
   - [Detailed sub-step]

4. **Verify the fix**
   - [How to confirm the issue is resolved]
   - Expected result: [what success looks like]

#### Alternative Solutions
If the primary resolution does not work:

1. **Alternative approach 1**: [brief description]
2. **Alternative approach 2**: [brief description]

#### Troubleshooting Tips
- [Common mistake to avoid]
- [Additional check if standard resolution fails]
- [Edge case that requires different handling]

#### If This Does Not Resolve the Issue
- Contact the IT helpdesk at [contact info]
- Reference this article: {{ article_title }}
- Include the following information in your ticket:
  - [What info to include]
  - [Error messages]
  - [Steps already attempted]

#### Related Articles
- [Link to related KB article 1]
- [Link to related KB article 2]

---

## Writing Guidelines

### Dos
- Write in clear, simple language appropriate for {{ audience }}
- Use numbered steps for procedures (not paragraphs)
- Include exact menu paths: Settings > Network > VPN
- Show exact error messages users might see
- Include screenshots for complex UI steps
- Test all procedures before publishing
- Set a review date (every 6 months)

### Don'ts
- Don't assume technical knowledge (for end-user articles)
- Don't use jargon without explanation
- Don't combine multiple topics in one article
- Don't include temporary workarounds without marking them clearly
- Don't publish without peer review

### SEO / Searchability
- Use keywords users would search for in the title
- Include common alternate terms (e.g., "WiFi" and "wireless")
- Include error message text verbatim for search matching

## Review & Publishing Workflow

1. [ ] Author drafts article using this template
2. [ ] Peer review by another agent/engineer
3. [ ] Technical accuracy verified (steps tested)
4. [ ] Approved by knowledge base manager
5. [ ] Published to appropriate audience (internal/external)
6. [ ] Added to relevant categories and tagged
7. [ ] Scheduled for periodic review

## Output Format

Generate a complete KB article following the structure above, ready for review and publishing.
