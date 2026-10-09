# agency-agents-to-multica

A mirror of [msitarzewski/agency-agents](https://github.com/msitarzewski/agency-agents)
reformatted for skill import into [Multica](https://github.com/multica-ai/multica).

Multica's importer (`multica skill import --url github.com/...`) requires the URL to
point at a file whose name ends in `SKILL.md`. Upstream publishes each persona as
`<division>/<persona>.md`, a format it rejects. This repo rewrites each persona as:

```
skills/<division>/<persona>/SKILL.md
```

## Automatic updates (layer 1)

The [`.github/workflows/sync-upstream.yml`](.github/workflows/sync-upstream.yml)
workflow runs hourly (and can be triggered manually under *Actions → sync-upstream →
Run workflow*): it clones upstream, regenerates `skills/` via `scripts/build-mirror.sh`,
and commits only when something changed. Personas added, renamed, or removed upstream
show up here on the next cycle.

## Importing into Multica (layer 2)

```bash
multica skill import \
  --url https://github.com/raphaelwdrf/agency-agents-to-multica/blob/main/skills/engineering/engineering-ai-engineer/SKILL.md
```

Once imported, the skill has a GitHub origin and can be re-fetched from source with
`multica skill refresh <id>` — upstream changes propagate into the Multica skills
without losing the id or any agent assignments (automatable with a Multica autopilot).

## Filtering scope

- Included: personas with `name:`/`description:` frontmatter from the divisions
  `academic design engineering finance game-development gis healthcare marketing
  paid-media product project-management research sales security spatial-computing
  specialized strategy support testing` (267 at initial sync).
- Excluded: `integrations/`, `examples/`, `scripts/`, `docs/` (conversion tooling and
  docs), READMEs, and the 3 strategy docs that lack frontmatter.

## Bulk import helper

`scripts/import-all.sh` walks every `SKILL.md` under `skills/`, imports each into
Multica (`--on-conflict skip`, so it is idempotent), and records the resulting ids to
`scripts/imported-ids.tsv` — handy for driving `multica skill refresh` in bulk.

## License

Personas and content: MIT, © AgentLand Contributors (upstream).
This repo's scripts: same purpose; feel free to use them.
