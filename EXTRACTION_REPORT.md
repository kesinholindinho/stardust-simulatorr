# Relatorio de Extracao

Arquivo analisado: `Iuno (1).rbxlx`
Scripts extraidos: 74

## Contagem por tipo

- Script: 25
- LocalScript: 16
- ModuleScript: 33

## Pastas principais encontradas

- ReplicatedStorage
- ServerScriptService
- StarterPlayer
- Workspace

## Scripts vazios

- ReplicatedStorage/EggConfig

## Avisos

- Nenhum

## Erros

- Nenhum

## Observacoes

- O extrator preserva a hierarquia encontrada no XML do Roblox sempre que possivel.
- Arquivos com nomes duplicados recebem sufixos como `_2` e `_3`.
- Scripts extraidos ficam em `extracted-scripts`; nada e apagado de `src` por este extrator.

## Arquivos .rbxlx encontrados

- `C:\Users\pedra\Downloads\Iuno (1).rbxlx` - 8539484 bytes - escolhido por ser o mais recente.
- `C:\Users\pedra\Downloads\Iuno.rbxlx` - 8539484 bytes.

O arquivo escolhido foi copiado para:

- `C:\Users\pedra\OneDrive\Área de Trabalho\StarDust\Iuno (1).rbxlx`

## Onde estao os arquivos extraidos

- `C:\Users\pedra\OneDrive\Área de Trabalho\StarDust\extracted-scripts`

## Comparacao e copia para src

Foram copiados automaticamente para `src` apenas scripts das areas permitidas:

- `ServerScriptService` para `src\ServerScriptService`
- `ReplicatedStorage` para `src\ReplicatedStorage`
- `StarterPlayer\StarterPlayerScripts` para `src\StarterPlayerScripts`

Resumo da copia:

- Scripts copiados para `src`: 60
- Arquivos existentes sobrescritos: 12
- Backup dos arquivos sobrescritos: `backup\src-before-copy-20260606-213725`

Os scripts de `Workspace` nao foram copiados para `src`, conforme solicitado. Eles continuam apenas em `extracted-scripts` para revisao futura.

## Backups criados

- `backup\20260606-213540`: backup dos arquivos de configuracao existentes antes da copia da pasta Codex.
- `backup\src-before-copy-20260606-213725`: backup dos scripts de `src` antes de sobrescrever arquivos equivalentes.
