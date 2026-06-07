# Revisao do nucleo do jogo - StarDust

Data: 2026-06-06

## O que foi analisado

Arquivos principais analisados:

```text
src/ServerScriptService/GameLogic.server.luau
src/ReplicatedStorage/StardustConfig.luau
src/StarterPlayerScripts/StardustGUI.client.luau
```

Tambem foram verificados arquivos usados diretamente ou ligados ao nucleo:

```text
src/ReplicatedStorage/StardustStyle.luau
src/ReplicatedStorage/StardustUI/PanelManager.luau
src/ReplicatedStorage/StardustUI/NetworkClient.luau
src/ReplicatedStorage/StardustUI/Panels/*.luau
src/StarterPlayerScripts/StarClickHandler.client.luau
src/StarterPlayerScripts/TradeClient.client.luau
src/ServerScriptService/InventoryServerScript.server.luau
src/ServerScriptService/QuestManager.server.luau
src/ServerScriptService/QuestServer.server.luau
src/ServerScriptService/TradeSystem.server.luau
src/ServerScriptService/LeaderstatsManager.server.luau
```

Sistemas revisados:

- Clique e ganho de Stardust.
- Sincronizacao de Stardust, Starcoins, level, XP, pets, upgrades, recompensa diaria e supernova.
- Compra de ovos e criacao de pets.
- Equipar, deletar, travar e fundir pets.
- Upgrades comprados por Stardust.
- Supernova, tokens e upgrades permanentes.
- Dependencias de UI e paineis do `StardustGUI`.
- RemoteEvents e RemoteFunctions usados pelo cliente e pelo servidor.

## Problemas encontrados e corrigidos

### 1. RemoteEvents principais nao estavam representados no Rojo

O nucleo do jogo usa `WaitForChild` para objetos como:

```text
GameAction
StardustSync
TutorialSync
InventoryAction
TradeAction
TradeSync
QuestRemotes
SettingsSync
ItemStardustEvent
QuestEvents
```

Esses objetos provavelmente existiam no `.rbxlx` original, mas nao aparecem no projeto Rojo quando apenas scripts sao extraidos. Sem eles, scripts como `GameLogic`, `QuestManager`, `QuestServer`, `TradeSystem`, `InventoryServerScript` e alguns clientes poderiam ficar presos esperando objetos que nunca seriam criados.

Correcao feita:

```text
src/ServerScriptService/CoreRemotes.server.luau
```

Esse novo script cria, se estiverem ausentes:

- `RemoteEvent`: `GameAction`, `StardustSync`, `TutorialSync`, `InventoryAction`, `SettingsSync`, `TradeAction`, `TradeSync`.
- `BindableEvent`: `ItemStardustEvent`.
- `Folder`: `QuestRemotes`.
- Dentro de `QuestRemotes`: `GetQuestData`, `QuestProgressUpdated`, `QuestClaimed`, `ClaimQuest`.
- `Folder` em `ServerStorage`: `QuestEvents`.
- Dentro de `QuestEvents`: `OnClick`, `OnStardustEarned`, `OnStardustSpent`, `OnItemUsed`, `OnItemBought`, `OnLevelUp`.

### 2. `getPetMultiplier` era usado antes de existir no escopo local

Em `GameLogic.server.luau`, a funcao `calculateClickReward` usava `getPetMultiplier` antes dessa funcao estar declarada no escopo local.

Isso poderia quebrar quando um pet salvo antigo nao tivesse o campo `multiplier`, porque o fallback tentaria chamar uma funcao global inexistente.

Correcao feita:

```text
src/ServerScriptService/GameLogic.server.luau
```

Foi adicionada uma declaracao antecipada:

```luau
local getPetMultiplier
```

E a funcao passou a preencher essa variavel local.

### 3. `ItemStardustEvent` era disparado, mas nao era ouvido pelo `GameLogic`

O `QuestManager` e o `InventoryServerScript` disparam `ItemStardustEvent` para recompensas de Stardust.

O proprio comentario do `QuestManager` dizia que o `GameLogic` ouviria esse evento, mas nao havia listener encontrado no `GameLogic`.

Correcao feita:

```text
src/ServerScriptService/GameLogic.server.luau
```

Foi criado um listener para `ItemStardustEvent`, que:

- valida o valor recebido;
- soma Stardust ao jogador;
- soma em `totalEarned`;
- sincroniza a interface com `syncToClient`.

### 4. `InventoryServerScript` chamava `addItem` antes da funcao estar no escopo local

O callback de `QuestItemReward` chamava `addItem`, mas `addItem` era declarada depois como funcao local.

Em Luau/Lua, isso pode fazer o callback procurar uma variavel global chamada `addItem`, em vez da funcao local correta.

Correcao feita:

```text
src/ServerScriptService/InventoryServerScript.server.luau
```

Foi adicionada declaracao antecipada:

```luau
local addItem
```

E a funcao passou a preencher essa variavel local.

## Modulos e requires

Os nomes principais usados por `require` em `ReplicatedStorage` batem com os arquivos existentes:

```text
StardustConfig
StardustStyle
QuestDefinitions
StardustUI/PanelManager
StardustUI/NetworkClient
StardustUI/Panels/AutoClickPanel
StardustUI/Panels/ShopPanel
StardustUI/Panels/SellPanel
StardustUI/Panels/UpgradesPanel
StardustUI/Panels/InventoryPanel
StardustUI/Panels/EggsPanel
StardustUI/Panels/PetsPanel
StardustUI/Panels/SupernovaPanel
StardustUI/Panels/WorldsPanel
StardustUI/Panels/QuestsPanel
StardustUI/Panels/DailyRewardPanel
StardustUI/Panels/SettingsPanel
StardustUI/Panels/LeaderboardPanel
StardustUI/Panels/TutorialPanel
```

Nao foi encontrada quebra obvia de nome de modulo nesses requires principais.

## Arquivos vazios

Foi feita busca por arquivos vazios dentro de `src`.

Resultado:

```text
Nenhum arquivo vazio encontrado em src.
```

O `EggConfig.luau` ja nao esta vazio: ele esta como modulo neutro documentado, conforme a limpeza pre-Rojo anterior.

## Pontos ainda duvidosos ou que precisam de teste no Roblox Studio

### `StardustUI` depende da interface original

`StardustGUI.client.luau`, `StarClickHandler.client.luau` e `TradeClient.client.luau` esperam encontrar:

```text
PlayerGui/StardustUI
```

Esse ScreenGui nao esta no mapeamento Rojo atual. Isso pode estar correto se o teste for feito em uma copia do jogo original, onde a UI ja existe no arquivo `.rbxlx`.

Se o teste for feito em um place limpo apenas com Rojo, a UI nao vai aparecer corretamente.

### Objetos do Workspace ainda precisam existir na copia do jogo

Algumas funcoes de mundo, boss, teleport e areas dependem de objetos no `Workspace`, que nao estao representados no Rojo.

Isso precisa ser testado na copia do jogo original, nao em um place vazio.

### Integracao completa de progresso de quests

O `QuestManager` escuta eventos como:

```text
OnClick
OnStardustEarned
OnStardustSpent
OnItemUsed
OnItemBought
OnLevelUp
```

Nesta revisao foram criados os BindableEvents para impedir travas, mas nao foi feita uma integracao completa espalhando disparos de progresso por todas as acoes do `GameLogic`.

Isso deve ser testado depois que o nucleo iniciar sem erros.

### Validacao Luau local

Foi verificado se existia comando local `luau` para validar sintaxe.

Resultado:

```text
luau nao encontrado
```

Entao a validacao foi feita por revisao estatica e buscas locais, nao por compilacao Luau.

## Arquivos alterados

Arquivos de codigo alterados/criados:

```text
src/ServerScriptService/CoreRemotes.server.luau
src/ServerScriptService/GameLogic.server.luau
src/ServerScriptService/InventoryServerScript.server.luau
```

Arquivo de relatorio criado:

```text
CORE_GAME_REVIEW.md
```

Backups criados antes das alteracoes:

```text
backup/core-review-20260606-222112/src/ServerScriptService/GameLogic.server.luau
backup/core-review-inventory-20260606-222309/src/ServerScriptService/InventoryServerScript.server.luau
```

## Verificacoes locais executadas

Verificacoes seguras executadas:

```text
default.project.json valido
nenhum arquivo vazio encontrado em src
luau nao encontrado
git status executado
git diff --stat executado
```

Status Git observado antes da criacao deste relatorio:

```text
## main...origin/main
 M src/ServerScriptService/GameLogic.server.luau
 M src/ServerScriptService/InventoryServerScript.server.luau
?? backup/core-review-20260606-222112/
?? backup/core-review-inventory-20260606-222309/
?? src/ServerScriptService/CoreRemotes.server.luau
```

## Proximo passo recomendado

O projeto esta mais seguro para um primeiro teste em uma copia do Roblox Studio.

Recomendacao:

1. Testar em uma copia do jogo original, nao no jogo principal.
2. Confirmar se o jogo inicia sem erro no Output.
3. Testar clique na estrela e verificar Stardust/XP no HUD.
4. Testar compra de upgrade.
5. Testar compra de ovo e equipar pet.
6. Testar recompensa de item/quest que usa `ItemStardustEvent`.
7. Depois disso, revisar especificamente progresso de quests e sistemas de boss.

