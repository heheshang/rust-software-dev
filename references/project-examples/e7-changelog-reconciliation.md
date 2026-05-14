# E7-Fallback CHANGELOG Reconciliation Recipe

> Appended from K线数据管理 pipeline recovery (2026-05-14 session).
> Documents the CHANGELOG merge pattern when T7 workspace and project CHANGELOG use different version header formats.

## Problem

T7 (tech-writer) workspace CHANGELOG and the project CHANGELOG use different version header conventions:

| Source | Header Format | Example |
|--------|--------------|---------|
| T7 workspace | `[0.5.0]` | `## [0.5.0] — 2026-05-13` |
| Project CHANGELOG | `v0.3.0` | `## v0.3.0 (2026-05-13)` |

Simply copying the T7 section verbatim would break the project's CHANGELOG formatting and section ordering.

## Verification Before Reconciliation

Always verify the divergence before touching files:

```python
import re

ws_changelog = "/path/to/t7_workspace/CHANGELOG.md"
project_changelog = "/path/to/project/CHANGELOG.md"

with open(ws_changelog) as f:
    ws_content = f.read()
with open(project_changelog) as f:
    proj_content = f.read()

# Check what version sections exist in each
ws_versions = re.findall(r"## \[[\d\.]+\]", ws_content)   # e.g. ['## [0.5.0]', '## [0.4.0]']
proj_versions = re.findall(r"## v[\d\.]+", proj_content) # e.g. ['## v0.3.0', '## v0.2.0']

ws_has_kline = "K 线数据管理模块" in ws_content
proj_has_v050 = "[0.5.0]" in proj_content or "## v0.5.0" in proj_content

print(f"T7 workspace versions: {ws_versions}")
print(f"Project versions: {proj_versions}")
print(f"T7 has K-line section: {ws_has_kline}")
print(f"Project has v0.5.0: {proj_has_v050}")
```

## Reconciliation Algorithm

```
1. Extract the complete version section from T7 workspace CHANGELOG
   (everything from "## [0.5.0]" to just before the next ## [...] or ## v... section)

2. Find the insertion point in the project CHANGELOG:
   - Search for the current latest version header (e.g., "## v0.3.0")
   - This is where the new section gets inserted (prepend = newest first)

3. Prepend the extracted section to project CHANGELOG
   - Do NOT re-format the section header — keep it as-is
   - Only insert once (the section already covers all submodule entries)

4. Verify:
   - New line count > old line count
   - v0.5.0 section appears before v0.3.0
   - No duplicate version headers
```

## Concrete Code

```python
import re

changelog_path = "/path/to/project/CHANGELOG.md"
with open(changelog_path) as f:
    content = f.read()

ws_changelog = "/path/to/t7_workspace/CHANGELOG.md"
with open(ws_changelog) as f:
    ws_content = f.read()

# Extract full [0.5.0] section from workspace CHANGELOG
# Pattern: from "## [0.5.0]" to before "## [0.4.0]" (or next version)
v050_match = re.search(
    r"(## \[0\.5\.0\] — \d{4}-\d{2}-\d{2}\n.*?)(?=\n## \[0\.4\.0\])", 
    ws_content, 
    re.DOTALL
)
v050_section = v050_match.group(1).strip() if v050_match else None

# Find insert point — prepend before the current latest version
insert_point = content.find("## v0.3.0")  # current latest in project

if insert_point > 0 and v050_section:
    new_content = v050_section + "\n\n" + content
    with open(changelog_path, 'w') as f:
        f.write(new_content)
    print("CHANGELOG reconciled")
```

## Key Insight

**T7 (tech-writer) workspace CHANGELOG sections use `[X.Y.Z]` format; the project CHANGELOG uses `vX.Y.Z` format.**

Both are valid Keep a Changelog formats. The reconciliation does NOT require converting one to the other — the project convention should be preserved by prepending the workspace section (which already has its own consistent header format) into the project.

## Related Notes

- CHANGELOG reconciliation is always needed when T7 workspace is archived with a CHANGELOG update — the workspace version section and project section will never be byte-identical.
- `diff` between workspace CHANGELOG and project CHANGELOG will show the entire section as a diff (not "SAME"), which is expected.
- Always check `diff` before and after to confirm the operation succeeded.
