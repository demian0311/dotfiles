# Release skill — finishing a release-all that died partway

## Finishing a release-all that died partway (until the resume issue, #1159, adds `--resume`)

release-all has no resume. If either half fails, it exits at the join with NO
deploys and NO board records. Finish it like this:

1. **Packages**: `scripts/release-cascade.sh --gates-on anchor <only the
   pairs npm does not serve yet>`. Check with `npm view <pkg> version`. If those
   shas already passed a gate, `--gates-on none` saves ~20 min. An unpushed
   `Release vX` commit + local tag from a refused push: nothing reached the
   remote, so check `git ls-remote --tags origin vX`, then `git tag -d` +
   `git reset --hard HEAD~1` (it is your own unpushed commit).
2. **App**: `cd diagrammo-app && ./release.sh --preflight --gates-on anchor
   --defer-tail --publish` (it can run during step 1). Then, after the cascade
   AND the site floors: `./release.sh --tail-only --publish`.
3. **Deploys + records**, the part that is easy to forget:
   ```bash
   cd diagrammo-cloud && bash -c "$(../scripts/issue-status.sh deploy-command diagrammo-cloud)"
   scripts/issue-status.sh deployed diagrammo-cloud $(git -C diagrammo-cloud rev-parse HEAD)
   bash -c "$(scripts/issue-status.sh deploy-command online-console)"
   scripts/issue-status.sh deployed online-console $(git rev-parse HEAD)
   scripts/issue-status.sh deployed diagrammo_app_site $(git -C diagrammo_app_site rev-parse HEAD)
   scripts/issue-status.sh shipped diagrammo-app
   scripts/issue-status.sh shipped dgmo      # release-all never runs these two —
   scripts/issue-status.sh shipped dgmo-mcp  # their Awaiting release rows stay open
   ```
   Before the Cloud deploy, `wrangler d1 migrations list diagrammo-cloud
   --remote` and read every pending `.sql`. Applied out of order (0046 before
   0044) does not mean held back — check the tracker, not the numbering.
4. **Verify live**: `npm view` each package, `curl -s https://diagrammo.app/latest.json`
   shows the new `version`, `gh release view vX -R diagrammo/releases` is not
   a draft, and `curl https://api.diagrammo.app/health` returns 200.
