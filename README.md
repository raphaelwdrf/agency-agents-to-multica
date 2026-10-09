# agency-agents-to-multica

Mirror de [msitarzewski/agency-agents](https://github.com/msitarzewski/agency-agents)
reformatado para importação de skills no [Multica](https://github.com/multica-ai/multica).

O importador do Multica (`multica skill import --url github.com/...`) exige que a URL
aponte para um arquivo terminado em `SKILL.md`. O upstream publica cada persona como
`<divisão>/<persona>.md`, formato que ele rejeita. Este repo reescreve cada persona como:

```
skills/<divisão>/<persona>/SKILL.md
```

## Atualização automática (camada 1)

O workflow [`.github/workflows/sync-upstream.yml`](.github/workflows/sync-upstream.yml)
roda de hora em hora (e manualmente em *Actions → sync-upstream → Run workflow*):
clona o upstream, regenera `skills/` via `scripts/build-mirror.sh` e commita só se mudou.
Personas adicionadas, renomeadas ou removidas no upstream aparecem aqui no próximo ciclo.

## Importar no Multica (camada 2)

```bash
multica skill import \
  --url https://github.com/raphaelwdrf/agency-agents-to-multica/blob/main/skills/engineering/engineering-ai-engineer/SKILL.md
```

Depois de importada, a skill ganha origem GitHub e pode ser recarregada do source com
`multica skill refresh <id>` — trocas no upstream propagam para as skills do Multica
sem perder id nem atribuições de agents (automatizável com autopilot no Multica).

## Escopo do filtro

- Incluídas: personas com frontmatter `name:`/`description:` das divisões
  `academic design engineering finance game-development gis healthcare marketing
  paid-media product project-management research sales security spatial-computing
  specialized strategy support testing` (267 no momento da sincroniza inicial).
- Excluídas: `integrations/`, `examples/`, `scripts/`, `docs/` (ferramentas de
  conversão e docs), READMEs e os 3 docs de estratégia sem frontmatter.

## Licença

Personas e conteúdo: MIT, © AgentLand Contributors (upstream).
Scripts deste repo: mesmo propósito; sinta-se livre.
