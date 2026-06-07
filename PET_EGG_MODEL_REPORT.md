# Relatorio de models de ovos e pets - StarDust

Data: 2026-06-06

## Resumo

O problema mais provavel era o mapeamento do `ReplicatedStorage` inteiro no `default.project.json`.

Antes, o projeto tinha:

```json
"ReplicatedStorage": {
  "$path": "src/ReplicatedStorage"
}
```

Isso fazia o Rojo gerenciar o `ReplicatedStorage` como uma pasta completa vinda de `src/ReplicatedStorage`. Como `src/ReplicatedStorage` contem apenas scripts/modulos extraidos, pastas de assets/modelos que existem no jogo original, como `PetModels`, `EggModels`, `Ovo Cosmico e seus Pets` e `Ovo Lunar e seus Pets`, podiam ser removidas/substituidas na copia do Roblox Studio durante o sync.

## Scripts analisados

Foram analisados os scripts principais de ovos, pets e visualizacao:

```text
src/ServerScriptService/GameLogic.server.luau
src/ServerScriptService/PetFollowSystem.server.luau
src/StarterPlayerScripts/PetAnimationClient.client.luau
src/StarterPlayerScripts/StardustGUI.client.luau
src/ReplicatedStorage/StardustConfig.luau
src/ReplicatedStorage/StardustUI/Panels/EggsPanel.luau
src/ReplicatedStorage/StardustUI/Panels/EggPetReveal.luau
src/ReplicatedStorage/StardustUI/Panels/PetsPanel.luau
```

## Caminhos de models esperados pelos scripts

### Pets seguindo o jogador

Arquivo:

```text
src/ServerScriptService/PetFollowSystem.server.luau
```

Esse script espera:

```text
ReplicatedStorage/PetModels
```

Ele usa:

```luau
local PET_MODELS = ReplicatedStorage:WaitForChild("PetModels")
```

Depois procura modelos com nomes como:

```text
Pet Gato Commun
Pet Galinha Commun
Pet Raposa Raro
Pet Morcego Raro
Pet Lobo Epico
Pet Coruja Epico
Pet Dragao Lendario
Pet Fenix Lendario
Pet BabyStar Commun
Pet GalacticOctopus Raro
Pet NebulaCreature Epico
Pet GalacticDragon Lendario
Pet LunarGhost Commun
Pet LunarComet Epico
Pet CrystalBear Raro
Pet LunarPhoenix Lendario
```

Se `ReplicatedStorage/PetModels` nao existir, esse script pode ficar preso no `WaitForChild` e os pets 3D nao aparecem seguindo o jogador.

### Reveal/animacao de pet ao abrir ovo

Arquivo:

```text
src/ReplicatedStorage/StardustUI/Panels/EggPetReveal.luau
```

Esse script procura primeiro pastas combinadas:

```text
ReplicatedStorage/Ovo Cosmico e seus Pets
ReplicatedStorage/Ovo Lunar e seus Pets
```

Depois tenta fallback em:

```text
ReplicatedStorage/PetModels
```

Se essas pastas nao existirem, o pet pode aparecer sem modelo 3D na animacao de abertura.

### Model de ovo na abertura

Arquivo:

```text
src/ReplicatedStorage/StardustUI/Panels/EggsPanel.luau
```

Esse script procura:

```text
ReplicatedStorage/Ovo Cosmico e seus Pets
ReplicatedStorage/Ovo Lunar e seus Pets
ReplicatedStorage/EggModels
Workspace
```

Ele usa `Clone()` quando encontra o model do ovo para mostrar/animar na UI.

### Configuracao de ovos/pets

Arquivo:

```text
src/ReplicatedStorage/StardustConfig.luau
```

Define ovos e nomes esperados dos pets:

```text
Ovo da Luz
Ovo Sombrio
EggCosmic
EggLunar
```

Para `EggCosmic` e `EggLunar`, os scripts tambem esperam models relacionados nas pastas:

```text
Ovo Cosmico e seus Pets
Ovo Lunar e seus Pets
```

## Verificacao das pastas no projeto

Resultado das checagens:

```text
src/ReplicatedStorage/PetModels: nao existe
src/ReplicatedStorage/EggModels: nao existe
extracted-scripts/ReplicatedStorage/PetModels: nao existe
extracted-scripts/ReplicatedStorage/EggModels: nao existe
```

Isso era esperado porque o extrator atual extraiu scripts, nao models, MeshParts, texturas ou assets complexos.

## Verificacao no .rbxlx original

O arquivo:

```text
Iuno (1).rbxlx
```

Contem referencias/objetos com estes nomes:

```text
PetModels
EggModels
Ovo Cosmico e seus Pets
Ovo Lunar e seus Pets
Ovo da Luz
Ovo Sombrio
```

Tambem ha uma descricao no proprio `.rbxlx` indicando:

```text
PetModels - 17 modelos de pets (meshes e texturas)
EggModels - Modelos de ovos
```

Conclusao: os models parecem existir no jogo original, mas nao foram trazidos para `src` porque nao sao scripts.

## Correcao segura feita

Foi criado backup antes de alterar:

```text
backup/pet-egg-model-review-20260606-223641/default.project.json
```

O arquivo alterado foi:

```text
default.project.json
```

Antes, `ReplicatedStorage` era mapeado inteiro para `src/ReplicatedStorage`.

Agora, o projeto mapeia apenas os scripts/modulos conhecidos dentro de `ReplicatedStorage`:

```text
ReplicatedStorage/EggConfig
ReplicatedStorage/QuestDefinitions
ReplicatedStorage/StardustConfig
ReplicatedStorage/StardustStyle
ReplicatedStorage/StardustUI
```

Novo comportamento esperado:

- Rojo continua sincronizando os modulos/scripts principais.
- Rojo nao deve substituir o `ReplicatedStorage` inteiro.
- Pastas de models/assets que ja existem na copia do Roblox Studio devem ser preservadas, como:
  - `PetModels`
  - `EggModels`
  - `Ovo Cosmico e seus Pets`
  - `Ovo Lunar e seus Pets`
  - outras pastas de assets que nao estao em `src`

Nao foi incluido `Workspace` no mapeamento.

Nao foram recriados MeshParts, modelos ou texturas por codigo.

## Observacao importante

Se a copia do Roblox Studio ja teve essas pastas removidas por um sync anterior, mudar o `default.project.json` impede que o problema continue acontecendo, mas nao recria automaticamente os models apagados da copia.

Nesse caso, o caminho seguro e:

1. Abrir uma copia nova do jogo original que ainda tenha `PetModels`, `EggModels` e as pastas dos ovos.
2. Conectar o Rojo usando este novo `default.project.json`.
3. Confirmar que as pastas de assets continuam em `ReplicatedStorage` depois do sync.

Alternativamente, copiar manualmente as pastas de models de uma copia intacta para a copia de teste.

## Verificacoes feitas

Verificacoes locais seguras:

```text
default.project.json valido
busca por PetModels/EggModels nos scripts
busca por PetModels/EggModels no .rbxlx
git status executado
```

Nao foi rodado `rojo serve`.

Nao houve conexao com Roblox Studio.

Nao houve commit ou push.

## O que testar no Roblox Studio agora

Em uma copia do jogo:

1. Antes de conectar/sincronizar, confirme se existem em `ReplicatedStorage`:
   - `PetModels`
   - `EggModels`
   - `Ovo Cosmico e seus Pets`
   - `Ovo Lunar e seus Pets`
2. Conecte o Rojo nessa copia.
3. Confirme se essas pastas continuam existindo depois do sync.
4. Compre/abra:
   - `Ovo da Luz`
   - `Ovo Sombrio`
   - `EggCosmic`
   - `EggLunar`
5. Confira se o model do ovo aparece na animacao.
6. Confira se o pet aparece no reveal.
7. Equipe o pet e confirme se ele aparece seguindo o jogador no mundo 3D.

## Proximo passo recomendado

Se os models ainda nao aparecerem depois dessa correcao de mapeamento, o proximo passo e comparar os nomes reais dentro de `ReplicatedStorage/PetModels` com os nomes esperados pelo `PetFollowSystem.server.luau`.

Nao recomendo recriar models complexos por codigo. O melhor e preservar ou copiar os models originais do `.rbxlx`/Studio.

