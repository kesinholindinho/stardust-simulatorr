# Relatorio de limpeza pre-Rojo - StarDust

Data: 2026-06-06

## Resumo

A limpeza segura antes do primeiro teste com Rojo foi executada sem rodar `rojo serve`, sem conectar no Roblox Studio, sem apagar arquivos definitivamente e sem alterar o arquivo `.rbxlx` original.

O projeto ficou mais seguro para um primeiro teste em uma copia do jogo, principalmente porque a pasta `src/ReplicatedStorage/123`, que parecia ser asset/modelo importado e nao um script principal, foi isolada fora do mapeamento do Rojo.

## Backups criados

Foi criado backup antes das alteracoes em:

```text
backup/pre-rojo-cleanup-20260606-220810
```

Itens copiados para backup:

```text
backup/pre-rojo-cleanup-20260606-220810/src/ReplicatedStorage/123
backup/pre-rojo-cleanup-20260606-220810/src/ReplicatedStorage/EggConfig.luau
```

## Assets isolados

Foi criada a pasta:

```text
isolated-assets/ReplicatedStorage
```

A pasta abaixo foi movida:

```text
src/ReplicatedStorage/123
```

Para:

```text
isolated-assets/ReplicatedStorage/123
```

Motivo: `123` parece ser um asset/modelo importado para `ReplicatedStorage`, nao um script principal esperado pelo Rojo. Deixar esse conteudo dentro de `src/ReplicatedStorage` poderia causar risco no primeiro sync/teste.

Status apos mover:

```text
src/ReplicatedStorage/123: nao existe mais
isolated-assets/ReplicatedStorage/123: existe
```

Nada foi apagado definitivamente.

## EggConfig

Arquivo verificado:

```text
src/ReplicatedStorage/EggConfig.luau
```

Resultado:

- O arquivo estava vazio em `src`.
- O arquivo extraido correspondente em `extracted-scripts/ReplicatedStorage/EggConfig.luau` tambem estava vazio.
- O `.rbxlx` contem o objeto `EggConfig`, mas nao foi encontrado conteudo real de `Source` para ele.
- Nao foi encontrado `require` direto de `EggConfig` nos scripts de `src`, `extracted-scripts` ou `backup`.
- A configuracao real de ovos parece estar em `src/ReplicatedStorage/StardustConfig.luau`, dentro da tabela `Config.EGGS`.

Como nao foi encontrado conteudo real para recuperar, nao foi criada configuracao falsa. O arquivo foi mantido como modulo neutro com comentario explicativo e retorno vazio:

```luau
-- EggConfig foi extraido vazio do arquivo .rbxlx original.
-- A checagem pre-Rojo nao encontrou require direto para este modulo.
-- A configuracao de ovos usada pelo jogo parece estar em ReplicatedStorage/StardustConfig.luau, na tabela Config.EGGS.
-- Mantido como ModuleScript neutro para preservar o objeto sem inventar configuracao falsa.

return {}
```

## Busca por ArenaBossStarPlatform

Foi encontrada diferenca importante entre nomes com e sem espaco no final.

### Com espaco no final

Busca por:

```text
"ArenaBossStarPlatform "
```

Ocorrencias:

```text
src/ServerScriptService/BossRewardSystem.server.luau:77
extracted-scripts/ServerScriptService/BossRewardSystem.server.luau:77
```

Linha encontrada:

```luau
local bossArena = game.Workspace:FindFirstChild("ArenaBossStarPlatform ")
```

### Sem espaco no final

Busca por:

```text
"ArenaBossStarPlatform"
```

Ocorrencias:

```text
src/ServerScriptService/BossSystem.server.luau:14
src/StarterPlayerScripts/BossHPBar.client.luau:13
extracted-scripts/ServerScriptService/BossSystem.server.luau:14
extracted-scripts/StarterPlayerScripts/BossHPBar.client.luau:13
```

Linhas encontradas:

```luau
local arenaPlatform = workspace:WaitForChild("ArenaBossStarPlatform", 10)
local arenaPlatform = workspace:WaitForChild("ArenaBossStarPlatform")
```

Observacao: nada foi renomeado automaticamente. Antes de testar, vale confirmar no Roblox Studio se o objeto real no `Workspace` se chama exatamente `ArenaBossStarPlatform` ou se possui um espaco no final. Essa diferenca pode quebrar sistemas do boss, incluindo recompensa, barra de vida ou deteccao de area.

## Busca por Crstal Tree pasta / Crystal Tree pasta

### Crstal Tree pasta

Busca por:

```text
Crstal Tree pasta
```

Ocorrencias em `src`:

```text
src/ReplicatedStorage/StardustUI/Panels/BossSkyChanger.luau:35
src/ServerScriptService/CrystalTreeAttackSystem.server.luau:15
src/ServerScriptService/CrystalTreeBossSystem.server.luau:31
src/ServerScriptService/CrystalTreeBossSystem.server.luau:32
src/ServerScriptService/CrystalTreeBossSystem.server.luau:158
src/ServerScriptService/CrystalTreeBossSystem.server.luau:257
src/ServerScriptService/CrystalTreeBossSystem.server.luau:455
src/StarterPlayerScripts/BossSkyLoader.client.luau:178
src/StarterPlayerScripts/CrystalBossClick.client.luau:19
src/StarterPlayerScripts/CrystalBossClient.client.luau:458
```

Ocorrencias tambem aparecem em `extracted-scripts`, incluindo:

```text
extracted-scripts/Workspace/Resumo do Jogo.server.luau:349
```

### Crystal Tree pasta

Busca por:

```text
Crystal Tree pasta
```

Resultado:

```text
Nenhuma ocorrencia encontrada.
```

Observacao: nada foi renomeado automaticamente. O nome `Crstal Tree pasta` parece escrito errado, mas pode ser o nome real do objeto dentro do jogo. Confirmar no Roblox Studio em uma copia antes de alterar.

## default.project.json

O arquivo `default.project.json` foi validado como JSON valido.

Mapeamentos atuais:

```text
src/ServerScriptService -> ServerScriptService
src/ReplicatedStorage -> ReplicatedStorage
src/StarterPlayerScripts -> StarterPlayer.StarterPlayerScripts
```

Depois de isolar `src/ReplicatedStorage/123`, o mapeamento ficou mais seguro porque `isolated-assets` nao faz parte do sync principal do Rojo.

## Status Git observado

Status observado apos a limpeza:

```text
## main...origin/main
 D src/ReplicatedStorage/123/Script.server.luau
 D src/ReplicatedStorage/123/Script/LightConfig.server.luau
 D src/ReplicatedStorage/123/Script/LightConfig/EasyConfiguration.luau
 D src/ReplicatedStorage/123/Script/LightConfig/Type.luau
 M src/ReplicatedStorage/EggConfig.luau
?? PROJECT_CHECK_REPORT.md
?? backup/pre-rojo-cleanup-20260606-220810/
?? isolated-assets/
```

As linhas com `D` sao esperadas porque a pasta `123` foi movida para `isolated-assets`, nao apagada.

## Pontos ainda sensiveis antes do teste

- Confirmar no Roblox Studio, usando uma copia do jogo, se o objeto do boss no `Workspace` se chama `ArenaBossStarPlatform` ou `ArenaBossStarPlatform ` com espaco no final.
- Confirmar se o objeto `Crstal Tree pasta` existe exatamente com esse nome no jogo original.
- Lembrar que alguns sistemas ainda dependem de objetos do `Workspace` que nao estao representados no Rojo.
- Testar primeiro em uma copia do jogo, nao no jogo principal.

## Proximos passos recomendados

1. Abrir uma copia do jogo no Roblox Studio.
2. Conectar/testar o Rojo somente na copia.
3. Verificar se a barra de vida do boss aparece ao entrar na area.
4. Se a barra nao aparecer, investigar primeiro os nomes reais dos objetos no `Workspace`, principalmente `ArenaBossStarPlatform`.
5. Se o boss nao receber dano, revisar os `RemoteEvents`, scripts de clique/ataque e scripts de servidor do boss depois que os nomes do `Workspace` forem confirmados.

