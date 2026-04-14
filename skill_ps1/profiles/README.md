# Profiles
Use profile files to adapt `skill_ps1` to different projects without changing script code.

Recommended flow:
1. Copy `project.profile.template.yaml`.
2. Rename to `project.profile.<project-name>.yaml`.
3. Fill `project_root`, `api`, `process`, and `ui` values.
4. Pass values from this file into templates as script parameters.

Starter examples:
- project.profile.local-api.yaml
- project.profile.ui-dashboard.yaml
