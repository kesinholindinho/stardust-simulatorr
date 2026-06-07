# Instrucoes Para Futuras IAs

Este e um projeto Roblox/Rojo do jogo **StarDust Simulator**.

Regras importantes:

- Nao rode Rojo no jogo principal sem confirmacao explicita do usuario.
- Nao rode `rojo serve` sem confirmacao explicita.
- Nao conecte automaticamente no Roblox Studio sem confirmacao.
- Antes de sobrescrever scripts em `src`, crie backup dentro da pasta `backup`.
- Nao modifique nem apague arquivos `.rbxlx` originais.
- Scripts de servidor devem usar a extensao `.server.luau`.
- Scripts de cliente devem usar a extensao `.client.luau`.
- ModuleScripts devem usar a extensao `.luau`.
- Scripts extraidos automaticamente devem ficar em `extracted-scripts` ate serem revisados.
- Quando houver duvida sobre equivalencia ou destino de um script, nao copie para `src`; registre a duvida no relatorio.

Estrutura esperada:

- `src/ServerScriptService` mapeia para `ServerScriptService`.
- `src/ReplicatedStorage` mapeia para `ReplicatedStorage`.
- `src/StarterPlayerScripts` mapeia para `StarterPlayer.StarterPlayerScripts`.

Use comentarios e documentacao em portugues quando criar arquivos para manutencao do projeto.
