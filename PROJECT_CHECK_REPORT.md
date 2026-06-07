# Relatorio de Checagem do Projeto StarDust

Data da checagem: 2026-06-06

## Escopo

Esta checagem analisou a estrutura local do projeto Roblox/Rojo em:

`C:\Users\pedra\OneDrive\Área de Trabalho\StarDust`

Nao foi executado `rojo serve`, nao houve conexao com Roblox Studio, nenhum arquivo foi apagado e nenhum push foi feito.

## O que esta certo

- `default.project.json` existe e esta em JSON valido.
- O mapeamento principal do Rojo esta coerente para um projeto de scripts:
  - `src/ServerScriptService` -> `ServerScriptService`
  - `src/ReplicatedStorage` -> `ReplicatedStorage`
  - `src/StarterPlayerScripts` -> `StarterPlayer.StarterPlayerScripts`
- As pastas principais existem:
  - `src/ServerScriptService`
  - `src/ReplicatedStorage`
  - `src/StarterPlayerScripts`
- O arquivo `.rbxlx` escolhido esta na raiz do projeto:
  - `Iuno (1).rbxlx`
- A extracao anterior gerou 74 scripts em `extracted-scripts`.
- Existem 60 scripts copiados para `src`.
- Os `require(...)` principais baseados em `ReplicatedStorage:WaitForChild(...)` apontam para arquivos existentes em `src`.
- Modulos importantes encontrados e usados pelo codigo existem:
  - `ReplicatedStorage/StardustConfig`
  - `ReplicatedStorage/QuestDefinitions`
  - `ReplicatedStorage/StardustStyle`
  - `ReplicatedStorage/StardustUI/PanelManager`
  - `ReplicatedStorage/StardustUI/NetworkClient`
  - paineis em `ReplicatedStorage/StardustUI/Panels`

## O que esta quebrado ou arriscado

### 1. `EggConfig` esta vazio

Arquivo vazio:

- `src/ReplicatedStorage/EggConfig.luau`

Ele tambem aparece vazio em `extracted-scripts`, entao o problema veio do `.rbxlx` ou esse ModuleScript realmente estava vazio no jogo.

Nesta checagem nao encontrei nenhum `require(EggConfig)` direto em `src`, entao ele talvez nao quebre o jogo imediatamente. Mesmo assim, e um ponto de atencao porque pelo nome parece configuracao importante de ovos.

### 2. Estrutura Rojo com scripts que tinham filhos no Roblox

Ha arquivos extraidos em formato que pode nao representar corretamente objetos com filhos no Rojo:

- `src/ReplicatedStorage/123/Script.server.luau`
- `src/ReplicatedStorage/123/Script/LightConfig.server.luau`
- `src/ReplicatedStorage/123/Script/LightConfig/Type.luau`
- `src/ReplicatedStorage/123/Script/LightConfig/EasyConfiguration.luau`

No Roblox original, alguns scripts parecem ter filhos, por exemplo `LightConfig` exige:

- `script:WaitForChild("Type")`
- `script:WaitForChild("EasyConfiguration", 5)`

Do jeito que esta no filesystem, Rojo pode interpretar `LightConfig.server.luau` e a pasta `LightConfig` como objetos separados, nao como filhos do mesmo Script. Isso pode quebrar esses `require(script:WaitForChild(...))`.

### 3. Pasta suspeita `ReplicatedStorage/123`

A pasta `src/ReplicatedStorage/123` parece ter vindo de algum asset/modelo importado, nao do sistema principal StarDust:

- contem script que mexe com `game.StarterPlayer.PlayerModule`
- contem script de camera/lighting
- tem nomes genericos como `123` e `Script`

Isso e arriscado para sincronizar via Rojo porque pode inserir codigo estranho em `ReplicatedStorage`. Provavelmente deveria ficar apenas em `extracted-scripts` ate revisao manual.

### 4. Scripts dependem de objetos do Workspace que nao estao no `default.project.json`

Varios scripts esperam objetos visuais/modelos existentes no jogo:

- `workspace:WaitForChild("Pet Boss")`
- `workspace:WaitForChild("ArenaBossStarPlatform")`
- `workspace:WaitForChild("Crstal Tree pasta")`
- `Area Crystal`
- `Boss Crystal Tree`

Isso nao e necessariamente erro se voce conectar o Rojo em uma copia do jogo completo que ja tem o mapa e os modelos. Mas se conectar em um lugar vazio, esses scripts vao falhar ou ficar desativados.

### 5. Nome com possivel erro de espaco

Em `src/ServerScriptService/BossRewardSystem.server.luau`, existe busca por:

- `ArenaBossStarPlatform ` com espaco no final

Ja outros scripts usam:

- `ArenaBossStarPlatform` sem espaco

Se o objeto real nao tiver espaco no final, o sistema de recompensa do boss pode nao encontrar a arena.

### 6. Nome `Crstal Tree pasta`

Varios scripts usam exatamente:

- `Crstal Tree pasta`

Isso parece escrito errado, mas pode ser o nome real no jogo. Antes de renomear qualquer coisa, confirme no Roblox Studio. Se no mapa estiver `Crystal Tree pasta`, os scripts do boss/cristal nao vao localizar a area.

## Requires analisados

Resultado da checagem automatica:

- Nenhum `require` simples para `ReplicatedStorage:WaitForChild(...)` ficou apontando para modulo inexistente.
- `EggConfig` nao foi encontrado como dependencia direta por `require(...)`.
- O unico ModuleScript vazio em `src` e `src/ReplicatedStorage/EggConfig.luau`.

Limite da checagem:

- `require` dinamico, `require(script.Parent...)`, `require(script:WaitForChild(...))` e referencias por variaveis precisam de revisao manual.
- O caso de `LightConfig` com filhos e o ponto mais suspeito desse grupo.

## O que precisa corrigir antes de testar no Roblox Studio

1. Revisar `src/ReplicatedStorage/EggConfig.luau`.
   - Se ele deveria ter configuracao de ovos, recuperar o conteudo do jogo original ou mover a configuracao para `StardustConfig`.
   - Se nao for usado, pode ficar vazio por enquanto, mas registre isso.

2. Remover ou isolar `src/ReplicatedStorage/123` antes de conectar Rojo no jogo principal.
   - Recomendado: manter essa pasta apenas em `extracted-scripts` ate entender de qual asset ela veio.
   - Nao apagar ainda; mover para backup seria mais seguro se voce decidir limpar.

3. Corrigir representacao de scripts com filhos se eles forem realmente necessarios.
   - Para Rojo, o formato mais seguro costuma ser uma pasta com `init.server.luau` e os filhos ao lado.
   - Exemplo conceitual:
     - `LightConfig/init.server.luau`
     - `LightConfig/Type.luau`
     - `LightConfig/EasyConfiguration.luau`

4. Conferir no Studio os nomes reais dos objetos de Workspace antes de testar sistemas de boss:
   - `Pet Boss`
   - `ArenaBossStarPlatform`
   - `ArenaBossStarPlatform ` com espaco no final
   - `Crstal Tree pasta`
   - `Area Crystal`
   - `Boss Crystal Tree`

5. Usar uma copia do lugar completo para o primeiro teste com Rojo.
   - Como o `default.project.json` nao mapeia `Workspace`, o projeto depende do mapa/modelos ja existirem no arquivo aberto no Studio.

## Recomendacao antes de conectar

Nao conectar no jogo principal ainda.

Antes disso, recomendo:

- Fazer uma copia do `.rbxlx`.
- Isolar ou revisar `src/ReplicatedStorage/123`.
- Confirmar se `EggConfig` deveria ter conteudo.
- Corrigir o possivel nome `ArenaBossStarPlatform ` com espaco, caso o objeto real nao tenha esse espaco.
- Depois testar em uma copia do jogo no Roblox Studio.
