List all open GitHub issues with label `ci-failure` in this repository using `gh issue list --label ci-failure --state open --json number,title,body`.

For each open issue found, do the following in sequence:

1. **Read the issue body** to extract the workflow name, branch, run URL, and commit message.

2. **Fetch the workflow run logs** using `gh run view <run-id> --log-failed` (extract the run ID from the run URL in the issue body) to understand exactly what failed.

3. **Diagnose the root cause** by reading the relevant files in the repository (workflows, source code, configs).

4. **Apply the fix** — edit the necessary files to resolve the failure.

5. **Commit and push** the fix following Conventional Commits format: `fix(ci): <description>` or `fix(<scope>): <description>` depending on the nature of the failure. Never use `git add .` — stage only the files changed by the fix.

6. **Close the issue** using:
   ```
   gh issue close <number> --comment "**Fix applied:** <one or two sentences describing exactly what was wrong and what was changed to fix it>"
   ```

After processing all issues, report a summary: how many issues were found, how many were fixed and closed, and whether any remain open (with reason if so).

If no issues with label `ci-failure` are open, report that and stop.
