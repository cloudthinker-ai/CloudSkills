#!/usr/bin/env python3
"""
Upgrade all CloudSkills SKILL.md files to match the new quality spec.

Improvements applied:
1. Description: Ensure "Use when..." activation trigger format
2. Counter-Rationalizations: Add section if missing
3. Output Format: Add section for connection skills if missing
4. Anti-Hallucination Rules: Add section for connection skills if missing
5. Standardize section naming (Two-Phase → Discovery-First)
"""

import os
import re
import sys

SKILLS_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "skills")

# Track stats
stats = {
    "total": 0,
    "desc_fixed": 0,
    "counter_rat_added": 0,
    "output_format_added": 0,
    "anti_halluc_added": 0,
    "already_improved": 0,  # aws-api-gateway and incident-response-runbook
    "skipped": 0,
}


def extract_frontmatter(content):
    """Extract frontmatter and body from SKILL.md content."""
    if not content.startswith("---"):
        return None, content
    end = content.index("---", 3)
    frontmatter = content[3:end].strip()
    body = content[end + 3:].strip()
    return frontmatter, body


def rebuild_content(frontmatter, body):
    """Rebuild SKILL.md content from frontmatter and body."""
    return f"---\n{frontmatter}\n---\n\n{body}\n"


def fix_description_connection(frontmatter, skill_name):
    """Fix connection skill description to start with 'Use when...'."""
    # Find the description block
    desc_match = re.search(
        r'(description:\s*\|?\s*\n)((?:\s+.*\n)*)',
        frontmatter
    )
    if not desc_match:
        return frontmatter, False

    desc_text = desc_match.group(2).strip()

    # Already starts with "Use when" or "use when"
    if desc_text.lower().startswith("use when"):
        return frontmatter, False

    # Extract the tool/service name from the skill name
    tool_name = skill_name.replace("analyzing-", "").replace("managing-", "").replace("monitoring-", "").replace("tracking-", "").replace("aws-", "AWS ").replace("gcp-", "GCP ").replace("azure-", "Azure ")
    tool_name = tool_name.replace("-", " ").title()

    # Build "Use when..." prefix
    # Parse existing description to extract key capabilities
    # Remove "You MUST read this skill..." boilerplate
    desc_text = re.sub(r'\s*You MUST read this skill[^.]*\.', '', desc_text)
    desc_text = re.sub(r'\s*it contains mandatory[^.]*\.', '', desc_text)
    desc_text = desc_text.strip()

    # If description already mentions the tool, convert to "Use when working with..."
    new_desc = f"Use when working with {tool_name} — {desc_text[0].lower()}{desc_text[1:]}"

    # Ensure it ends with a period
    if not new_desc.rstrip().endswith("."):
        new_desc = new_desc.rstrip() + "."

    # Rebuild frontmatter with new description
    indent = "  "
    # Wrap at ~80 chars
    words = new_desc.split()
    lines = []
    current_line = indent
    for word in words:
        if len(current_line) + len(word) + 1 > 80:
            lines.append(current_line)
            current_line = indent + word
        else:
            if current_line == indent:
                current_line += word
            else:
                current_line += " " + word
    if current_line.strip():
        lines.append(current_line)

    new_desc_block = "\n".join(lines) + "\n"
    new_frontmatter = frontmatter[:desc_match.start()] + f"description: |\n{new_desc_block}" + frontmatter[desc_match.end():]

    return new_frontmatter, True


def fix_description_template(frontmatter, skill_name):
    """Fix template skill description to start with 'Use when...'."""
    desc_match = re.search(
        r'(description:\s*\|?\s*\n)((?:\s+.*\n)*)',
        frontmatter
    )
    if not desc_match:
        return frontmatter, False

    desc_text = desc_match.group(2).strip()

    if desc_text.lower().startswith("use when"):
        return frontmatter, False

    # Extract workflow name from skill name
    workflow_name = skill_name.replace("-", " ")

    # Build "Use when..." prefix
    new_desc = f"Use when performing {workflow_name} — {desc_text[0].lower()}{desc_text[1:]}"
    if not new_desc.rstrip().endswith("."):
        new_desc = new_desc.rstrip() + "."

    indent = "  "
    words = new_desc.split()
    lines = []
    current_line = indent
    for word in words:
        if len(current_line) + len(word) + 1 > 80:
            lines.append(current_line)
            current_line = indent + word
        else:
            if current_line == indent:
                current_line += word
            else:
                current_line += " " + word
    if current_line.strip():
        lines.append(current_line)

    new_desc_block = "\n".join(lines) + "\n"
    new_frontmatter = frontmatter[:desc_match.start()] + f"description: |\n{new_desc_block}" + frontmatter[desc_match.end():]

    return new_frontmatter, True


def get_tool_from_connection_type(frontmatter):
    """Extract the connection_type from frontmatter."""
    m = re.search(r'connection_type:\s*(\S+)', frontmatter)
    return m.group(1) if m else "unknown"


def generate_counter_rationalizations_connection(skill_name, tool):
    """Generate counter-rationalizations for a connection skill."""
    # Common tool-agnostic rationalizations
    display_name = skill_name.replace("-", " ").replace("analyzing ", "").replace("managing ", "").replace("monitoring ", "").replace("tracking ", "").title()

    return f"""
## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "I'll skip discovery and check known resources" | Always run Phase 1 discovery first | Resource names change, new resources appear — assumed names cause errors |
| "The user only asked for a quick check" | Follow the full discovery → analysis flow | Quick checks miss critical issues; structured analysis catches silent failures |
| "Default configuration is probably fine" | Audit configuration explicitly | Defaults often leave logging, security, and optimization features disabled |
| "Metrics aren't needed for this" | Always check relevant metrics when available | API/CLI responses show current state; metrics reveal trends and intermittent issues |
| "I don't have access to that" | Try the command and report the actual error | Assumed permission failures prevent useful investigation; actual errors are informative |
"""


def generate_counter_rationalizations_template(skill_name):
    """Generate counter-rationalizations for a template skill."""
    workflow_name = skill_name.replace("-", " ")

    return f"""
## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |
"""


def generate_output_format_connection(skill_name, tool):
    """Generate an output format section for connection skills that lack one."""
    display_name = skill_name.replace("-", " ").title()

    return f"""
## Output Format

Present results as a structured report:
```
{display_name} Report
{'═' * (len(display_name) + 7)}
Resources discovered: [count]

Resource       Status    Key Metric    Issues
──────────────────────────────────────────────
[name]         [ok/warn] [value]       [findings]

Summary: [total] resources | [ok] healthy | [warn] warnings | [crit] critical
Action Items: [list of prioritized findings]
```

Target ≤50 lines of output. Use tables for multi-resource comparisons.
"""


def generate_anti_hallucination_connection(skill_name, tool):
    """Generate anti-hallucination rules for connection skills that lack them."""
    display_name = tool.replace("-", " ").title()

    return f"""
## Anti-Hallucination Rules

1. **NEVER assume resource names** — always discover via CLI/API in Phase 1 before referencing in Phase 2.
2. **NEVER fabricate metric names or dimensions** — verify against the service documentation or `--help` output.
3. **NEVER mix CLI commands between service versions** — confirm which version/API you are targeting.
4. **ALWAYS use the discovery → verify → analyze chain** — every resource referenced must have been discovered first.
5. **ALWAYS handle empty results gracefully** — an empty response is valid data, not an error to retry.
"""


def process_connection_skill(filepath, skill_name):
    """Process a single connection skill."""
    content = open(filepath, "r").read()
    frontmatter, body = extract_frontmatter(content)
    if frontmatter is None:
        return False

    tool = get_tool_from_connection_type(frontmatter)
    modified = False

    # 1. Fix description
    frontmatter, desc_changed = fix_description_connection(frontmatter, skill_name)
    if desc_changed:
        stats["desc_fixed"] += 1
        modified = True

    # 2. Add counter-rationalizations if missing
    if "counter-rational" not in body.lower():
        # Insert before "## Common Pitfalls" if it exists, else at the end
        cr_section = generate_counter_rationalizations_connection(skill_name, tool)
        pitfalls_match = re.search(r'\n## Common Pitfalls', body)
        if pitfalls_match:
            body = body[:pitfalls_match.start()] + cr_section + body[pitfalls_match.start():]
        else:
            body = body.rstrip() + "\n" + cr_section
        stats["counter_rat_added"] += 1
        modified = True

    # 3. Add output format if missing
    if "## output format" not in body.lower():
        of_section = generate_output_format_connection(skill_name, tool)
        # Insert before counter-rationalizations or common pitfalls
        cr_match = re.search(r'\n## Counter-Rationalizations', body)
        pitfalls_match = re.search(r'\n## Common Pitfalls', body)
        insert_point = cr_match or pitfalls_match
        if insert_point:
            body = body[:insert_point.start()] + of_section + body[insert_point.start():]
        else:
            body = body.rstrip() + "\n" + of_section
        stats["output_format_added"] += 1
        modified = True

    # 4. Add anti-hallucination rules if missing
    if "anti-hallucination" not in body.lower():
        ah_section = generate_anti_hallucination_connection(skill_name, tool)
        # Insert before counter-rationalizations
        cr_match = re.search(r'\n## Counter-Rationalizations', body)
        if cr_match:
            body = body[:cr_match.start()] + ah_section + body[cr_match.start():]
        else:
            of_match = re.search(r'\n## Output Format', body)
            if of_match:
                body = body[:of_match.start()] + ah_section + body[of_match.start():]
            else:
                body = body.rstrip() + "\n" + ah_section
        stats["anti_halluc_added"] += 1
        modified = True

    if modified:
        new_content = rebuild_content(frontmatter, body)
        open(filepath, "w").write(new_content)

    return modified


def process_template_skill(filepath, skill_name):
    """Process a single template skill."""
    content = open(filepath, "r").read()
    frontmatter, body = extract_frontmatter(content)
    if frontmatter is None:
        return False

    modified = False

    # 1. Fix description
    frontmatter, desc_changed = fix_description_template(frontmatter, skill_name)
    if desc_changed:
        stats["desc_fixed"] += 1
        modified = True

    # 2. Add counter-rationalizations if missing
    if "counter-rational" not in body.lower():
        cr_section = generate_counter_rationalizations_template(skill_name)
        # Insert before "## Output Format" if it exists, else at the end
        of_match = re.search(r'\n## Output Format', body)
        if of_match:
            body = body[:of_match.start()] + cr_section + body[of_match.start():]
        else:
            body = body.rstrip() + "\n" + cr_section
        stats["counter_rat_added"] += 1
        modified = True

    if modified:
        new_content = rebuild_content(frontmatter, body)
        open(filepath, "w").write(new_content)

    return modified


def main():
    # Already-improved skills (skip these)
    skip_skills = {"aws-api-gateway", "incident-response-runbook"}

    # Process connection skills
    conn_dir = os.path.join(SKILLS_DIR, "connections")
    for skill_dir in sorted(os.listdir(conn_dir)):
        skill_path = os.path.join(conn_dir, skill_dir, "SKILL.md")
        if not os.path.exists(skill_path):
            continue
        stats["total"] += 1

        if skill_dir in skip_skills:
            stats["already_improved"] += 1
            continue

        try:
            process_connection_skill(skill_path, skill_dir)
        except Exception as e:
            print(f"ERROR processing {skill_dir}: {e}", file=sys.stderr)
            stats["skipped"] += 1

    # Process template skills
    tmpl_dir = os.path.join(SKILLS_DIR, "templates")
    for skill_dir in sorted(os.listdir(tmpl_dir)):
        skill_path = os.path.join(tmpl_dir, skill_dir, "SKILL.md")
        if not os.path.exists(skill_path):
            continue
        stats["total"] += 1

        if skill_dir in skip_skills:
            stats["already_improved"] += 1
            continue

        try:
            process_template_skill(skill_path, skill_dir)
        except Exception as e:
            print(f"ERROR processing {skill_dir}: {e}", file=sys.stderr)
            stats["skipped"] += 1

    # Print stats
    print(f"\n{'='*50}")
    print(f"Skills Upgrade Complete")
    print(f"{'='*50}")
    print(f"Total skills processed: {stats['total']}")
    print(f"Already improved (skipped): {stats['already_improved']}")
    print(f"Descriptions fixed to 'Use when...': {stats['desc_fixed']}")
    print(f"Counter-rationalizations added: {stats['counter_rat_added']}")
    print(f"Output format sections added: {stats['output_format_added']}")
    print(f"Anti-hallucination rules added: {stats['anti_halluc_added']}")
    print(f"Errors/skipped: {stats['skipped']}")
    print(f"{'='*50}")


if __name__ == "__main__":
    main()
