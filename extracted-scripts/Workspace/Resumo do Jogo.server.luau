--[[
	╔══════════════════════════════════════════════════════════════════════════╗
	║                STARDUST SIMULATOR - RESUMO COMPLETO                       ║
	║                Documentacao Completa do Jogo                              ║
	╚══════════════════════════════════════════════════════════════════════════╝

	Este script contem documentacao completa de como o jogo funciona.
	NAO E um script funcional - apenas para leitura e referencia.

	Ultima atualizacao: Documentacao completa revisada e corrigida
	Data: Janeiro 2025
]]

--[[
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	                           VISAO GERAL DO JOGO
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

	Stardust Simulator e um jogo clicker/idle ambientado em um mundo cosmico
	onde jogadores coletam Stardust, chocam pets, completam missoes e
	progridem atraves de multiplos mundos.

	GENERO: Clicker/Idle Game
	TEMA: Fantasia Cosmica

	FLUXO DE JOGO:
	1. Clicar na estrela → Ganhar Stardust + XP
	2. Comprar upgrades → Aumentar multiplicadores
	3. Chocar ovos → Obter pets com multiplicadores
	4. Equipar pets → Multiplicador de Stardust passivo + por clique
	5. Vender Stardust → Obter Starcoins (moeda premium)
	6. Comprar ovos premium → Pets mais raros
	7. Enfrentar bosses → Recompensas especiais
	8. Completar missoes → Stardust, titulos, multiplicadores
	9. Supernova (prestige) → Tokens + multiplicador permanente
	10. Trocar pets com outros jogadores
]]

--[[
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	                        SISTEMA DE MOEDAS
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

	STARDUST (Moeda Primaria):
	- Obtida clicando na estrela principal (base: 1 por clique)
	- Obtida passivamente por pets equipados (a cada 1 segundo)
	- Obtida por recompensas diarias, missoes, bosses
	- Usada para comprar itens, upgrades, ovos normais
	- Pode ser vendida por Starcoins
	- Multiplicadores: pets, upgrades, gamepass 2x, zonas bonus, supernova, boosts

	STARCOINS (Moeda Premium):
	- Obtida vendendo Stardust (50 Stardust = 1 Starcoin)
	- Usada para comprar ovos premium (Cosmic e Lunar)
	- Obtida como recompensa de bosses

	SUPERNOVA TOKENS (Moeda de Prestige):
	- Obtidos ao realizar Supernova (1 + supernovaCount tokens por reset)
	- Usados na Supernova Token Shop (pets exclusivos, upgrades permanentes, titulos)
]]

--[[
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	                        SISTEMA DE PETS
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

	RARIDADES (6 tipos, multiplicadores base):
	- Common: 1x multiplicador
	- Raro: 2x multiplicador
	- Epico: 5x multiplicador
	- Lendario: 10x multiplicador
	- Especial: 15x multiplicador
	- Supernova: 25x multiplicador

	PET STAR SYSTEM (1-5 estrelas):
	- Cada pet comeca com 1 estrela
	- Cada estrela adicional adiciona +1.0x ao multiplicador
	- Exemplo: Pet Raro (2x) com 3 estrelas = 2x + 2.0x = 4x total
	- Efeitos de particulas visuais por nivel de estrela

	PET MERGE SYSTEM:
	- 3 pets identicos (mesmo nome, mesmas estrelas) = +1 estrela
	- Maximo: 5 estrelas
	- Pets equipados ou trancados nao podem ser mergeados
	- Auto-Merge: encontra e mergeia automaticamente todos os grupos possiveis
	- Prioriza grupos de menor numero de estrelas

	PET LOCK SYSTEM:
	- Trancar/Destrancar pets para proteger contra exclusao e troca
	- Pets trancados nao podem ser deletados, mergeados ou oferecidos em troca
	- Toggle de cadeado na interface de pets

	PETS DISPONIVEIS POR OVO:

	Ovo da Luz (Stardust):
	- Dragao (Lendario) - 10x
	- Lobo (Epico) - 5x
	- Morcego (Raro) - 2x
	- Galinha (Common) - 1x

	Ovo Sombrio (Stardust):
	- Fenix (Lendario) - 10x
	- Coruja (Epico) - 5x
	- Raposa (Raro) - 2x
	- Gato (Common) - 1x

	EggCosmic (Starcoins):
	- Galactic Dragon (Lendario) - 10x
	- Nebula Creature (Epico) - 5x
	- Galactic Octopus (Raro) - 2x
	- Baby Star (Common) - 1x

	EggLunar (Starcoins):
	- Lunar Phoenix (Lendario) - 10x
	- Crystal Bear (Epico) - 5x
	- Lunar Comet (Raro) - 2x
	- Lunar Ghost (Common) - 1x

	SUPERNOVA TOKEN SHOP PETS:
	- Nova Dragon (Supernova) - 8.0x (5 tokens)
	- Stellar Phoenix (Supernova) - 10.0x (8 tokens)
	- Cosmic Emperor (Supernova) - 12.0x (12 tokens)

	BOSS REWARD PETS:
	- PetMiniAstroKing (Lendario) - 6.0x (derrotar AstroKing)
	- PetMiniCrystal (Raro) - 2.0x (Crystal Tree Gacha)
	- PetCrystalTree (Lendario) - 6.0x (Crystal Tree Gacha)

	EQUIPAR PETS:
	- Maximo 3 pets (padrao)
	- Maximo 6 pets (com gamepass "More Pets")
	- Pets seguem o jogador em formacao de arco
	- Pets equipados geram Stardust passivo a cada 1 segundo
	- Rendimento passivo = soma dos multiplicadores dos pets equipados

	HATCH CHANCES (pesos por raridade):
	- Common: peso 50
	- Raro: peso 15
	- Epico: peso 5
	- Lendario: peso 1
]]

--[[
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	                        SISTEMA DE OVOS
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

	OVOS NORMAIS (Stardust):

	1. Ovo da Luz:
	   - 1x: 50 Stardust
	   - 3x: 120 Stardust
	   Raridade do ovo: Especial
	   Pets: Dragao (Lendario), Lobo (Epico), Morcego (Raro), Galinha (Common)

	2. Ovo Sombrio:
	   - 1x: 50 Stardust
	   - 3x: 120 Stardust
	   Raridade do ovo: Especial
	   Pets: Fenix (Lendario), Coruja (Epico), Raposa (Raro), Gato (Common)

	OVOS PREMIUM (Starcoins):

	3. EggCosmic:
	   - 1x: 30 Starcoins
	   - 3x: 75 Starcoins
	   Raridade do ovo: Lendario
	   Pets: Galactic Dragon (Lendario), Nebula Creature (Epico),
	         Galactic Octopus (Raro), Baby Star (Common)

	4. EggLunar:
	   - 1x: 30 Starcoins
	   - 3x: 75 Starcoins
	   Raridade do ovo: Lendario
	   Pets: Lunar Phoenix (Lendario), Crystal Bear (Epico),
	         Lunar Comet (Raro), Lunar Ghost (Common)

	OVOS DECORATIVOS (nao implementados no sistema de hatch):
	- Ovo Elritch (Workspace)
	- Ovo Inferno (Workspace)
	- Ovo Vintage (Workspace)
]]

--[[
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	                        SISTEMA DE UPGRADES
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

	1. Click Power: +5% Stardust por clique (nivel base: 5, preco base: 1200)
	2. Super Click: +10% chance de double Stardust (nivel base: 3, preco base: 2500)
	3. Star Burst: +15% Stardust de estrelas (nivel base: 1, preco base: 5000)
	4. Constellation Bonus: +20% XP de todas fontes (nivel base: 0, preco base: 8000)
	5. Moon Power: +8% Stardust a noite (nivel base: 2, preco base: 3500)

	PRECO ESCALONADO: preco = preco base x (nivel atual + 1)
]]

--[[
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	                        SISTEMA DE SUPERNOVA
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

	O QUE E: Sistema de prestige/reset de progresso
	REQUISITO: 10,000 Stardust total ganho (totalEarned)

	RECOMPENSAS POR SUPERNOVA:
	- Tokens: 1 + supernovaCount (ex: 1ª vez = 1 token, 2ª vez = 2 tokens, etc.)
	- Token Bonus upgrade: +1 token extra por Supernova (compra na Token Shop)
	- Multiplicador: 1.0 + (supernovaCount × 0.1)
	  Ex: 1ª Supernova = 1.1x, 2ª = 1.2x, 3ª = 1.3x...

	RESETA AO FAZER SUPERNOVA:
	- Stardust → 0 (ou 500 com Start Boost upgrade)
	- Starcoins → 0
	- totalEarned → 0
	- Level → 1 (ou 5 com XP Headstart upgrade)
	- XP → 0
	- Upgrades → mantidos (nao resetam)
	- Pets → mantidos (nao resetam)
	- Permanent Upgrades → mantidos
	- Titulos → mantidos
	- Supernova Count/Tokens/Multiplier → mantidos e incrementados

	SUPERNOVA TOKEN SHOP:

	Pets Exclusivos (3):
	- Nova Dragon (Supernova, 8.0x) - 5 tokens
	- Stellar Phoenix (Supernova, 10.0x) - 8 tokens
	- Cosmic Emperor (Supernova, 12.0x) - 12 tokens

	Upgrades Permanentes (4):
	- Start Boost: Comece com +500 Stardust apos reset - 3 tokens
	- XP Headstart: Comece no nivel 5 apos reset - 5 tokens
	- Token Bonus: +1 Token extra por Supernova - 8 tokens
	- Multiplier Boost: +0.2 multiplicador base permanente - 15 tokens

	Titulos Cosmeticos (4):
	- Starborn ⭐ - 3 tokens
	- Nova Master 💥 - 6 tokens
	- Cosmic Lord 🌌 - 10 tokens
	- Stellar God 👑 - 20 tokens
]]

--[[
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	                        SISTEMA DE MISSOES
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

	TIPOS DE MISSOES (23 total):

	1. Daily (Diarias): Resetam a cada 24 horas (8 missoes)
	   - Click Starter: 1,000 cliques (50 Stardust)
	   - Stardust Collector: 5,000 Stardust (100 Stardust)
	   - Item Enthusiast: 10 itens usados (80 Stardust)
	   - Clicking Pro: 10,000 cliques (300 Stardust)
	   - Stardust Hoarder: 100,000 Stardust (500 Stardust)
	   - Shopaholic: 3 itens comprados (200 Stardust)
	   - Dedicated Player: 30 min jogando (120 Stardust)
	   - Speed Clicker: 500 CPM (800 Stardust)

	2. Weekly (Semanais): Resetam toda segunda-feira (7 missoes)
	   - Weekly Clicker: 100,000 cliques (2,000 Stardust)
	   - Consistent Player: 5 dias de login (5,000 Stardust)
	   - Item User: 5 itens usados (1,500 Stardust)
	   - Level Up: 3 niveis ganhos (3,000 Stardust)
	   - Big Spender: 50,000 Stardust gastos (10,000 Stardust + item)
	   - Click Master: 1,000 CPM (8,000 Stardust)
	   - Dedicated Week: 60 min jogando (4,000 Stardust)

	3. Lifetime (Vitalicias): Nunca resetam (8 missoes)
	   - Beginner Clicker: 10,000 cliques (500 Stardust + titulo "Beginner")
	   - Veteran Clicker: 500,000 cliques (5,000 Stardust + titulo "Veteran")
	   - Billionaire Clicker: 10M cliques (titulo "Billionaire")
	   - Stardust Master: 1B Stardust (item exclusivo)
	   - Level Master: Nivel 100 (multiplicador 1.1x)
	   - Week Warrior: 7 dias de login (2,000 Stardust + item)
	   - Shop Regular: 100 itens comprados (titulo "Obsessed Buyer")
	   - Item Collector: 999 itens comprados (titulo "Legendary")

	TIPOS DE OBJETIVOS:
	- CLICKS, TOTAL_LIFETIME_CLICKS
	- STARDUST_EARNED, TOTAL_LIFETIME_STARDUST
	- STARDUST_SPENT, ITEMS_BOUGHT, ITEMS_USED
	- LEVELS_GAINED, LEVEL_REACHED
	- PLAYTIME_MINUTES, CLICKS_PER_MINUTE
	- LOGIN_STREAK

	TIPOS DE RECOMPENSA:
	- Stardust (direto via ItemStardustEvent)
	- Titulos (armazenados em unlockedTitles)
	- Multiplicadores (armazenados em multiplierBonuses)
	- Itens (via QuestItemReward BindableEvent → InventoryServerScript)

	DATASTORE: "QuestData_v1"
	RESET: Daily a cada 24h, Weekly toda segunda-feira UTC
	AUTO-SAVE: Debounce a cada 5 segundos (apenas dados sujos)
]]

--[[
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	                     SISTEMA DE RECOMPENSAS DIARIAS
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

	Dia 1: 100 Stardust
	Dia 2: 150 Stardust
	Dia 3: 250 Stardust
	Dia 4: 400 Stardust
	Dia 5: 600 Stardust
	Dia 6: 800 Stardust
	Dia 7: 1200 Stardust

	Ciclo: Reseta ao completar dia 7 (volta ao dia 1)
	Claim: 1 por dia (24h cooldown)
	Historico: claimedDaysHistory rastreia dias ja coletados
]]

--[[
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	                     SISTEMA DE BOSS
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

	2 CHEFES:

	1. AstroKing (Pet Boss)
	   - Local: ArenaBossStarPlatform (Workspace.Pet Boss)
	   - HP: BASE_HP x playerCount (base 5,000, max 50,000)
	   - Dano: baseado no clickPower do jogador
	   - Anti-spam: 0.1s cooldown entre danos do mesmo jogador
	   - Respawn: 10 minutos (600 segundos)
	   - Recompensas proporcionais ao dano contribuido:
	     * Stardust: damagePercent x 200
	     * XP: +500 bonus
	     * PetMiniAstroKing (Lendario, 6.0x):
	       - Top damage dealer: garantido
	       - >=20% dano: 30% chance
	       - >=10% dano: 15% chance
	       - Outros: 5% chance

	   BOSS ATTACK SYSTEM (Stake Attacks):
	   - Intervalo: 8 segundos entre ataques
	   - 1-3 posicoes aleatorias na arena por ataque
	   - Aviso visual: 2.5 segundos antes do impacto
	   - Raio de dano: 6 studs
	   - Dano: 15 HP por acerto
	   - Notificacao ao cliente via BossAttackEvent
	   - Para quando o boss morre, reinicia ao respawnar

	2. Crystal Tree
	   - Local: Crstal Tree pasta (Workspace)
	   - HP dinamico baseado nos jogadores na area
	   - Formula HP: avgClickPower x numPlayers x 500 (minimo 1,000)
	   - Respawn: 10 minutos (600 segundos)
	   - Recompensas proporcionais ao dano contribuido:
	     * Stardust base: 3,000 (escala com contribuicao)
	     * Starcoins base: 300 (escala com contribuicao)
	     * +3 Gacha Shots por derrota

	GACHA SYSTEM (Crystal Tree):
	- Cada shot rola 5 cartas independentes
	- Probabilidades por carta:
	  1. Stardust (★)        -- 25% (300-600, ou 600-900 se high damage)
	  2. Starcoins (◆)       -- 20% (25-50, ou 50-75 se high damage)
	  3. Crystal Shard (◈)    -- 15% (consumivel: 2x Stardust por 5 min)
	  4. XP Boost (▲)        -- 15% (consumivel: 2x XP por 10 min)
	  5. PetMiniCrystal (✦)   -- 12% (Raro, 2.0x)
	  6. PetCrystalTree (✤)   -- 4% (Lendario, 6.0x)
	  7. MISS (✕)             -- 9% (nenhuma recompensa)

	High damage (>30% do HP total) = melhores recompensas numericas
	Shots sao salvos permanentemente, sem limite maximo
]]

--[[
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	                        SISTEMA DE MUNDOS
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

	5 MUNDOS:
	1. Ilha do Cogumelo (livre) - Cogumelos magicos
	2. Asteroide (50,000 totalEarned) - Campo de asteroides perigoso
	3. StarPlace (250,000 totalEarned) - Lugar das estrelas brilhantes
	4. Terra Morta (1,000,000 totalEarned) - Terra abandonada e misteriosa
	5. Crystal Tree (livre) - Ilha do boss Crystal Tree

	Teleporte requer totalEarned suficiente (exceto Ilha do Cogumelo e Crystal Tree)
	Teleporte via painel Worlds ou TeleportButtons
]]

--[[
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	                        GAMEPASSES
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

	1. 2x Stardust (ID: 1817317562): 
	   - Dobra todo Stardust ganho
	   - Indicador visual: Badge dourado "✨ 2x Stardust" no canto superior esquerdo
	   - Pulsa com animacao suave

	2. More Pets (ID: 1816119729): 
	   - Permite equipar ate 6 pets (em vez de 3)
	   - Multiplicador total maior

	3. 2x XP (ID: 1814337737): 
	   - Dobra todo XP ganho
	   - Indicador visual: Badge azul "⭐ 2x XP" no canto superior esquerdo
	   - Pulsa com animacao suave

	4. Auto Click Star (ID: 1818211451): 
	   - AutoClick 2x mais rapido (0.25s vs 0.5s gratuito)
	   - 4 cliques automaticos por segundo (gamepass)
	   - 2 cliques automaticos por segundo (gratuito)
	   - Indicador visual: Badge verde "🔄 AutoClick 2x" no canto superior esquerdo
	   - Banner dourado "🔄 Auto Click Star ATIVO!" no painel AutoClick
	   - Botao toggle para alternar entre versao gamepass e gratuita
]]

--[[
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	                        LOJA (SHOP)
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

	CATEGORIA 1 - ITENS DE COLECAO (SHOP_ITEMS):
	- Star Fragment: 100 Stardust -> +100 Stardust
	- Shooting Star: 250 Stardust -> +300 Stardust
	- Bright Star: 500 Stardust -> +600 Stardust
	- Magic Dust: 150 Stardust -> +200 Stardust
	- Moon Stone: 800 Stardust -> +1000 Stardust
	- Comet Tail: 350 Stardust -> +450 Stardust

	CATEGORIA 2 - BOOSTS TEMPORARIOS (BOOST_ITEMS):
	- Star Potion: 200 Stardust -> 3x Stardust por 3 min
	- Click Frenzy: 500 Stardust -> 5x cliques por 2 min
	- Lucky Star: 350 Stardust -> +50% rare drops por 5 min
	- Crystal Shard: 150 Stardust -> 2x Stardust por 5 min
	- XP Boost: 200 Stardust -> 2x XP por 10 min

	INVENTARIO:
	- Itens de colecao sao consumidos ao usar (ganho de Stardust)
	- Valores de uso: Star Fragment=100, Shooting Star=300, Bright Star=600,
	  Magic Dust=200, Moon Stone=1000, Comet Tail=450
	- Boosts temporarios mostram timer visual na UI
]]

--[[
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	                     SCRIPTS DO SERVIDOR (15)
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

	1. GameLogic - Script principal (cliques, vendas, upgrades, ovos, pets)
	   - Gerencia todas as acoes do jogo via RemoteEvent GameAction
	   - Sistema de moedas: Stardust e Starcoins
	   - Sistema de niveis e XP (formula: xpNeeded = 100 * level^1.5)
	   - Sistema de upgrades (5 tipos)
	   - Sistema de ovos (4 tipos: Luz, Sombrio, Cosmico, Lunar)
	   - Sistema de pets: equipar, deletar, merge, lock, auto-merge
	   - Sistema de recompensas diarias
	   - Sistema de Supernova (prestige)
	   - Sistema de renda passiva de pets (1 segundo por tick)
	   - Sistema de boosts temporarios
	   - Integracao com QuestEvents
	   - Auto-save a cada 60 segundos
	   - Expoe funcoes globais: _G.getPlayerData, _G.savePlayerData, _G.syncToClient

	2. InventoryServerScript - Gerencia inventario e uso de itens
	   - Armazena itens comprados na loja
	   - Usa itens para ganhar Stardust
	   - Recebe itens de missoes via QuestItemReward BindableEvent

	3. QuestManager - Rastreamento de progresso de missoes
	   - Escuta BindableEvents: OnClick, OnStardustEarned, OnItemBought, etc.
	   - Atualiza progresso e verifica conclusao
	   - Auto-save debounce a cada 5 segundos

	4. LeaderstatsManager - Cria e atualiza leaderboard
	   - Exibe Daily, Weekly, Lifetime (contagem de missoes completadas)
	   - Atualiza via QuestRemotes.GetQuestData

	5. QuestServer - Gerenciamento de dados de missoes
	   - DataStore: "QuestData_v1"
	   - Reset: Daily a cada 24h, Weekly toda segunda-feira UTC

	6. BossSystem - Gerencia boss AstroKing
	   - HP, dano, recompensas, stake attacks
	   - Cria RemoteEvents: BossSync, BossAttackEvent

	7. CrystalTreeAttackSystem - Animacoes de ataque do Crystal Tree

	8. CrystalTreeBossSystem - HP, dano e recompensas do Crystal Tree
	   - HP dinamico baseado em jogadores
	   - Sistema de gacha com 5 cartas por shot, 3 shots por derrota
	   - Rastreamento de dano por jogador
	   - Cria RemoteEvents: CrystalBossSync, BossAttackEvent

	9. PetFollowSystem - Pets seguindo o jogador
	   - Formacao de arco ao redor do jogador
	   - Escuta PetSpawnEvent BindableEvent

	10. GamepassManager - Gerencia gamepasses

	11. BossRewardSystem - Recompensas por derrotar chefes

	12. ShopProximitySystem - DESABILITADO

	13. TradeSystem - Sistema de troca de pets entre jogadores
	   - Requisicao/aceitacao/recusa de trocas
	   - Validacao: pets equipados ou trancados nao podem ser oferecidos
	   - Max 9 pets por troca
	   - Janela de confirmacao de 5 segundos
	   - Limpeza de requisicoes obsoletas (30s timeout)
	   - RemoteEvents: TradeAction, TradeSync

	14. TestScript - Script de teste (debug)

	15. TestScript2 - Script de teste (debug)
]]

--[[
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	                     SCRIPTS DO CLIENTE (16)
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

	1. StardustGUI - Script principal de UI (15 paineis)
	   - Gerencia todos os paineis da interface
	   - Sistema de notificacoes configuravel
	   - Indicadores visuais de gamepasses
	   - Badges: 2x Stardust, 2x XP, AutoClick 2x

	2. StarClickHandler - Clique na estrela principal
	   - Detecta cliques na estrela e envia ao servidor
	   - Feedback visual/sonoro por clique
	   - Calcula e exibe CPM (cliques por minuto)

	3. QuestClient - UI de missoes
	   - Exibe missoes Daily, Weekly, Lifetime
	   - Progresso em tempo real
	   - Claim de recompensas

	4. PetAnimationClient - Efeitos visuais nos pets
	   - Efeitos de particulas por nivel de estrela
	   - Animacoes de spawn e merge

	5. BossHPBar - Barra de vida do boss
	   - Barra de HP com nome e dano percentual
	   - Atualizacao em tempo real via BossSync

	6. BossSkyLoader - Muda skybox durante batalhas
	   - Carrega skybox de batalha ao entrar na arena
	   - Restaura skybox normal ao sair

	7. BossAttackClient - Feedback visual de ataques do AstroKing
	   - Aviso visual de stake attacks (2.5s antes)
	   - Efeito de impacto e dano no jogador
	   - Recebe dados via BossAttackEvent

	8. CrystalBossClient - UI do Crystal Tree
	   - Barra de HP do Crystal Tree
	   - Interface de gacha (card flip)
	   - Sincronizacao via CrystalBossSync

	9. CrystalBossClick - Interacao com Crystal Tree
	   - Detecta cliques no Crystal Tree
	   - Envia dano ao servidor

	10. BonusZoneIndicator - Indicador de zonas de bonus
	   - Mostra quando jogador esta em zona de bonus (2x Stardust)
	   - Feedback visual na tela

	11. TeleportButtons - Teleporte entre mundos
	   - Botoes de teleporte para cada mundo
	   - Verifica requisito de totalEarned

	12. ShopUIClient - Interacoes da loja
	   - Compra de itens e boosts
	   - Feedback de compra

	13. ButtonSoundManager - Gerencia sons de botoes
	   - Toca sons ao clicar botoes da UI

	14. CrystalAttackSoundClient - Sons de ataque do Crystal Tree
	   - Efeitos sonoros durante batalha do Crystal Tree

	15. LoadingScreen - Tela de carregamento
	   - Exibida ao entrar no jogo
	   - Transicao suave para gameplay

	16. TradeClient - UI de troca de pets
	   - Envio e recebimento de requisicoes de troca
	   - Selecao de pets para oferecer
	   - Confirmacao e cancelamento de trocas
	   - Comunicacao via TradeAction e TradeSync
]]

--[[
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	                        REPLICATED STORAGE
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

	MODULES (4 ModuleScripts):
	- StardustStyle - Estilizacao de UI (cores, fontes, tamanhos)
	- StardustConfig - Configuracoes do jogo (pets, ovos, upgrades, shop)
	- QuestDefinitions - Definicoes de missoes (23 missoes, 3 categorias)
	- EggConfig - Configuracao de ovos (4 tipos, pets, chances)

	REMOTE EVENTS (9):
	- GameAction - Comunicacao principal (cliques, vendas, upgrades, ovos, pets)
	- StardustSync - Sincronizacao de dados do jogador (servidor→cliente)
	- InventoryAction - Operacoes de inventario (usar itens)
	- BossSync - Sincronizacao de batalha AstroKing (HP, dano, recompensas)
	- BossAttackEvent - Notificacao de stake attacks do AstroKing (servidor→cliente)
	- CrystalBossSync - Sincronizacao de batalha Crystal Tree (HP, gacha, recompensas)
	- TradeAction - Acoes de troca (enviar, aceitar, recusar, confirmar)
	- TradeSync - Sincronizacao de estado de troca (servidor→cliente)
	- TutorialSync - Sincronizacao do tutorial (servidor→cliente)

	QUEST REMOTES (pasta):
	- QuestRemotes.GetQuestData - Solicitar dados de missoes
	- QuestRemotes.ClaimReward - Resgatar recompensa de missao
	- QuestRemotes.ResetQuests - Resetar missoes (admin/debug)

	BINDABLE EVENTS (3):
	- QuestEvents (pasta com multiplos eventos):
	  * OnClick - Dispara ao clicar na estrela
	  * OnStardustEarned - Dispara ao ganhar Stardust
	  * OnItemBought - Dispara ao comprar item
	  * OnItemUsed - Dispara ao usar item
	  * OnLevelUp - Dispara ao subir de nivel
	  * OnStardustSpent - Dispara ao gastar Stardust
	  * OnPlaytime - Dispara periodicamente (tempo de jogo)
	- PetSpawnEvent - Notifica quando pet e criado/equipado
	- QuestItemReward - Entrega itens como recompensa de missao

	FOLDERS:
	- StardustUI - Assets e paineis de UI (15 paineis + PanelManager + helpers)
	- PetModels - 17 modelos de pets (meshes e texturas)
	- EggModels - Modelos de ovos
	- CharacterPreviews - Previews de personagens

	OUTROS:
	- 123 (pasta) - Scripts de iluminacao
	  * Script - Script de iluminacao principal
	  * Script.LightConfig - Configuracao de iluminacao
	  * Script.LightConfig.EasyConfiguration - Config facil
	  * Script.LightConfig.Type - Tipo de iluminacao
]]

--[[
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	                        UI PAINEIS (15 + HELPERS)
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

	1. AutoClickPanel - Auto-clicker
	   - Toggle ON/OFF
	   - Indicador de gamepass (banner dourado)
	   - Botao para alternar entre gamepass e gratuito

	2. ShopPanel - Comprar itens
	   - 2 categorias: SHOP_ITEMS (6 itens) e BOOST_ITEMS (5 boosts)
	   - Precos em Stardust

	3. SellPanel - Vender Stardust
	   - Converter Stardust em Starcoins
	   - Taxa: 50 Stardust = 1 Starcoin

	4. UpgradesPanel - Comprar upgrades
	   - 5 upgrades disponiveis

	5. InventoryPanel - Inventario
	   - Itens comprados e consumiveis
	   - Usar itens para ganhar Stardust
	   - Itens: Star Fragment, Shooting Star, Bright Star, Magic Dust,
	     Moon Stone, Comet Tail, Crystal Star, Comet Core, Nebula Dust

	6. EggsPanel - Chocar pets
	   - 4 ovos disponiveis
	   - Ovos premium em Starcoins

	7. PetsPanel - Colecao de pets
	   - Ver todos os pets
	   - Equipar/desequipar
	   - Filtrar por raridade
	   - Merge (3 iguais = +1 estrela)
	   - Auto-Merge
	   - Lock/Unlock (cadeado)

	8. SupernovaPanel - Resetar progresso
	   - Requisito: 10,000 totalEarned
	   - Recompensa: tokens e multiplicador
	   - Token Shop: 3 pets, 4 upgrades, 4 titulos

	9. WorldsPanel - Teleporte
	   - 5 mundos disponiveis
	   - Teleporte requer totalEarned (exceto Ilha do Cogumelo e Crystal Tree)

	10. QuestsPanel - Missoes
	   - Daily (8), Weekly (7), Lifetime (8)
	   - Progresso em tempo real
	   - Claim de recompensas

	11. DailyRewardPanel - Recompensas diarias
	   - 7 dias de recompensas (100, 150, 250, 400, 600, 800, 1200)
	   - Ciclo reseta ao completar dia 7

	12. SettingsPanel - Configuracoes
	   - Musica, Som, Particulas, Notificacoes

	13. LeaderboardPanel - Rankings
	   - Exibe Daily, Weekly, Lifetime (contagem de missoes completadas)
	   - Atualizacao via QuestRemotes.GetQuestData

	14. TutorialPanel - Tutorial do jogo
	   - Guia passo-a-passo para novos jogadores
	   - Sincronizacao via TutorialSync

	15. TradePanel - Troca de pets
	   - Enviar/aceitar/recusar requisicoes de troca
	   - Selecionar pets para oferecer
	   - Max 9 pets por troca

	SCRIPTS AUXILIARES DE UI:
	- PanelManager - Gerencia troca entre paineis (abrir/fechar)
	- EggExplosion - Animacao de explosao ao chocar ovo
	- EggClose - Botao de fechar UI de ovos
	- EggOverlay - Overlay durante animacao de hatch
	- EggPetReveal - Revelacao do pet apos hatch
	- BossSkyChanger - Muda skybox durante batalhas de boss
	- NetworkClient - Comunicacao de rede com servidor
]]

--[[
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	                        ESTRUTURA DE DADOS
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

	PlayerData:
	- stardust, starcoins, level, xp, xpNeeded, clickPower
	- totalEarned (total acumulado de Stardust - para Supernova e mundos)
	- autoClickEnabled, equippedPets, ownedPets
	- inventory, upgrades, dailyReward, supernova
	- bossDefeated, crystalTreeShots
	- settings: {music, sound, particles, notifications}
	- stardustBoostEndTime, stardustBoostMultiplier (Crystal Shard)
	- xpBoostEndTime, xpBoostMultiplier (XP Boost)
	- supernova: {count, tokens, multiplier, permanentUpgrades, unlockedTitles}
	- multiplierBonuses (de missoes lifetime)
	- tutorialCompleted

	PetData:
	- id, name, emoji, rarity, multiplier
	- stars (1-5, cada estrela +1.0x multiplicador)
	- locked (protege contra exclusao, merge e troca)
	- equipped, obtainedAt, isBossReward

	QuestData:
	- daily, weekly, lifetime
	- loginStreak, lifetimeStats

	BossState:
	- currentHP, maxHP, isAlive, isUnderground
	- respawnEndTime, playersInArea
	- totalDamageDealt (por jogador)
]]

--[[
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	                        DATASTORE
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

	NAMESPACES:
	- "StardustPlayerData" - Dados do jogador
	- "QuestData_v1" - Dados de missoes

	AUTO-SAVE:
	- A cada 60 segundos
	- Ao jogador sair
]]

--[[
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	                        SISTEMA DE TUTORIAL
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

	- Guia passo-a-passo para novos jogadores
	- TutorialPanel na UI com instrucoes interativas
	- Sincronizacao via TutorialSync RemoteEvent
	- Estado salvo em tutorialCompleted no PlayerData
	- Exibido apenas na primeira vez que o jogador entra
]]

--[[
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	                        SISTEMA DE TROCA (TRADE)
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

	SERVIDOR (TradeSystem - ServerScriptService):
	- Jogadores podem enviar requisicoes de troca de pets
	- Validacao: pets equipados ou trancados nao podem ser oferecidos
	- Max 9 pets por lado da troca
	- Janela de confirmacao de 5 segundos apos ambas aceitarem
	- Limpeza automatica de requisicoes obsoletas (30s timeout)
	- RemoteEvents: TradeAction (cliente→servidor), TradeSync (servidor→cliente)

	CLIENTE (TradeClient - StarterPlayerScripts):
	- TradePanel na UI para selecionar pets e gerenciar trocas
	- Envio, aceitacao e recusa de requisicoes
	- Feedback visual do estado da troca
]]

--[[
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	                     SCRIPTS DO WORKSPACE (5)
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

	1. Water.Script - Animacao de agua (ondas)
	2. WorkspaceTestScript - Script de teste (debug)
	3. CoreSkyboxSystem (Workspace.Meat) - Sistema de skybox dinamico
	4. Rain (Workspace.Rain) - Sistema de chuva
	5. SkyLink (Workspace["SkyLink (Dont Remove)"]) - Sistema de skybox
	   - EZConfig - Configuracao facil
	   - EZConfig.Type - Tipo de skybox
	   - EZConfig.EasyConfiguration - Configuracao detalhada

	LIGHTING SCRIPTS (3):
	- LightConfig - Configuracao de iluminacao
	- LightConfig.Type - Tipo de iluminacao
	- LightConfig.EasyConfiguration - Configuracao facil de iluminacao

	REPLICATED STORAGE SCRIPTS (2):
	- 123.Script - Script de iluminacao principal
	- 123.Script.LightConfig - Configuracao de iluminacao
	- 123.Script.LightConfig.EasyConfiguration - Config facil
	- 123.Script.LightConfig.Type - Tipo de iluminacao
]]

--[[
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	                        RESUMO FINAL
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

	Stardust Simulator e um jogo clicker/idle completo com:

	✓ Sistema de moedas triplo (Stardust + Starcoins + Supernova Tokens)
	✓ Sistema de pets com 21+ pets e 6 raridades (Common, Raro, Epico, Lendario, Especial, Supernova)
	✓ Pet Star System (1-5 estrelas, +1.0x por estrela)
	✓ Pet Merge System (3 iguais = +1 estrela, ate 5 estrelas)
	✓ Pet Lock System (proteger pets contra exclusao/troca)
	✓ Renda passiva de pets (Stardust a cada 1 segundo)
	✓ Sistema de upgrades com 5 tipos
	✓ Sistema de Supernova (prestige) com Token Shop
	✓ Sistema de missoes (Daily/Weekly/Lifetime - 23 missoes)
	✓ Sistema de recompensas diarias (7 dias, multiplicador por ciclo)
	✓ Sistema de zonas bonus (2x Stardust)
	✓ Sistema de boss (2 chefes: AstroKing e Crystal Tree)
	✓ Boss Attack System (AstroKing stake attacks, 15 dano, 6 stud raio)
	✓ Sistema de gacha Crystal Tree (7 cartas, card flip UI)
	✓ Sistema de troca de pets (TradeSystem, max 9 pets, 5s confirmacao)
	✓ Sistema de tutorial para novos jogadores
	✓ Consumiveis: Crystal Shard (2x Stardust 5min) e XP Boost (2x XP 10min)
	✓ 4 gamepasses com indicadores visuais
	✓ AutoClick gamepass 2x mais rapido (0.25s vs 0.5s)
	✓ UI completa com 15 paineis + scripts auxiliares
	✓ Persistencia de dados (DataStore)
	✓ 5 mundos para explorar
	✓ Personagens chibi com animacoes
	✓ Efeitos visuais e musica ambiente
	✓ Sistema de notificacoes configuravel
	✓ DEV PERKS para testadores

	SCRIPTS TOTAL:
	- Servidor: 15 scripts (ServerScriptService)
	- Cliente: 16 scripts (StarterPlayerScripts)
	- Modulos: 4 ModuleScripts (ReplicatedStorage)
	- Workspace: 5 scripts (Water, WorkspaceTestScript, CoreSkyboxSystem, Rain, SkyLink)
	- Lighting: 3 scripts (LightConfig, Type, EasyConfiguration)
	- ReplicatedStorage: 2 scripts (123 folder)
	- Total: 45+ scripts

	O jogo segue boas praticas:
	- Logica no servidor
	- UI no cliente
	- Comunicacao via RemoteEvents (9) e BindableEvents (3)
	- Validacao server-side
	- DataStore para save (2 namespaces)
	- Rate limiting para prevenir exploit
	- Debounce em eventos de toque
	- Anti-spam em boss damage (0.1s cooldown)
]]

-- Fim da documentacao
-- Este script e apenas para leitura e referencia
-- Nao contem codigo funcional