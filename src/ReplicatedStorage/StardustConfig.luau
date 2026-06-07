local Config = {}

-- ============================================
-- ECONOMY CONFIGURATION (Centralized)
-- ============================================
Config.ECONOMY = {
    -- Base click power (Stardust earned per click without multipliers)
    BASE_CLICK_POWER = 1,
    
    -- Starcoin conversion rate (how much Stardust = 1 Starcoin)
    STARCOIN_CONVERSION_RATE = 50,
    
    -- Supernova requirement (total Stardust earned to unlock)
    SUPERNOVA_REQUIREMENT = 10000,
    
    -- Normal egg prices (Stardust)
    NORMAL_EGG_PRICE_1 = 50,   -- Price for 1 egg
    NORMAL_EGG_PRICE_3 = 120,  -- Price for 3 eggs (bundle discount)
    
    -- Premium egg prices (Starcoins)
    PREMIUM_EGG_PRICE_1 = 30,  -- Price for 1 premium egg
    PREMIUM_EGG_PRICE_3 = 75,  -- Price for 3 premium eggs (bundle discount)
}

-- ============================================
-- COLORS
-- ============================================
Config.COLORS = {
    MAIN_BG = Color3.fromRGB(20, 20, 20),
    SECONDARY_BG = Color3.fromRGB(35, 35, 35),
    BUTTON_BG = Color3.fromRGB(50, 50, 50),
    TITLE_TEXT = Color3.fromRGB(220, 220, 220),
    DESC_TEXT = Color3.fromRGB(170, 170, 170),
    BORDER = Color3.fromRGB(80, 80, 80),
    DIVIDER = Color3.fromRGB(60, 60, 60),
    CLOSE_BTN = Color3.fromRGB(60, 60, 60),
    CLOSE_HOVER = Color3.fromRGB(90, 90, 90),
    BUTTON_HOVER = Color3.fromRGB(65, 65, 65),
    BUTTON_CLICK = Color3.fromRGB(80, 80, 80),
    SHADOW = Color3.fromRGB(5, 5, 5),
    ACTIVE_BORDER = Color3.fromRGB(160, 160, 160),
    XP_FILL = Color3.fromRGB(180, 180, 180),
    TOGGLE_OFF = Color3.fromRGB(60, 60, 60),
    TOGGLE_ON = Color3.fromRGB(150, 150, 150),
    SUCCESS = Color3.fromRGB(100, 200, 100)
}

-- ============================================
-- RARITY COLORS
-- ============================================
-- FIX: Padronizar nomes de raridade (usar português como padrão)
Config.RARITY_COLORS = {
    -- Português (padrão do servidor)
    ["Common"] = Color3.fromRGB(150, 150, 150),
    ["Raro"] = Color3.fromRGB(100, 150, 255),
    ["Epico"] = Color3.fromRGB(180, 100, 255),
    ["Lendario"] = Color3.fromRGB(255, 200, 50),
    ["Especial"] = Color3.fromRGB(255, 150, 200),
    ["Premium"] = Color3.fromRGB(255, 215, 0),
    ["Supernova"] = Color3.fromRGB(255, 100, 255), -- New rarity for Supernova pets
    -- Inglês (compatibilidade)
    ["Rare"] = Color3.fromRGB(100, 150, 255),
    ["Epic"] = Color3.fromRGB(180, 100, 255),
    ["Legendary"] = Color3.fromRGB(255, 200, 50),
    ["Mythic"] = Color3.fromRGB(255, 100, 100),
    -- Gacha boss pets
    ["PetCrystalTree"] = Color3.fromRGB(255, 200, 50),
    ["PetMiniCrystal"] = Color3.fromRGB(100, 200, 255)
}

-- FIX: Ordem de raridade para filtros
Config.RARITY_ORDER = {
    -- Português (padrão do servidor)
    ["Common"] = 1,
    ["Raro"] = 2,
    ["Epico"] = 3,
    ["Lendario"] = 4,
    ["Especial"] = 5,
    ["Premium"] = 6,
    ["Supernova"] = 7, -- Highest rarity
    -- Inglês (compatibilidade)
    ["Rare"] = 2,
    ["Epic"] = 3,
    ["Legendary"] = 4,
    ["Mythic"] = 5
}

-- FIX: Função helper para obter cor de raridade
function Config.GetRarityColor(rarity)
    return Config.RARITY_COLORS[rarity] or Config.RARITY_COLORS["Common"]
end

-- FIX: Função helper para obter ordem de raridade
function Config.GetRarityOrder(rarity)
    return Config.RARITY_ORDER[rarity] or 1
end

-- ============================================
-- TWEEN INFO
-- ============================================
Config.TWEEN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
Config.TWEEN_INFO_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
Config.CORNER_RADIUS = 0.12

-- ============================================
-- SHOP ITEMS - TWO CATEGORIES
-- ============================================

-- Category 1: TEMPORARY CONSUMABLE BOOSTS
-- These give temporary effects with visual timers
Config.BOOST_ITEMS = {
    {emoji = "🧪", name = "Star Potion", desc = "3x Stardust por 3 min", price = 200, effect = "stardustBoost", duration = 180, multiplier = 3},
    {emoji = "⚡", name = "Click Frenzy", desc = "5x cliques por 2 min", price = 500, effect = "clickBoost", duration = 120, multiplier = 5},
    {emoji = "🍀", name = "Lucky Star", desc = "+50% rare drops por 5 min", price = 350, effect = "luckyBoost", duration = 300, multiplier = 1.5},
    {emoji = "💎", name = "Crystal Shard", desc = "2x Stardust por 5 min", price = 150, effect = "stardustBoost", duration = 300, multiplier = 2},
    {emoji = "📚", name = "XP Boost", desc = "2x XP por 10 min", price = 200, effect = "xpBoost", duration = 600, multiplier = 2}
}

-- Category 2: MISSION/COLLECTION ITEMS
-- Fixed prices with neutral or positive returns
Config.SHOP_ITEMS = {
    {emoji = "⭐", name = "Star Fragment", desc = "Coleção: +100 Stardust", price = 100, stardustGain = 100},
    {emoji = "💫", name = "Shooting Star", desc = "Coleção: +300 Stardust", price = 250, stardustGain = 300},
    {emoji = "🌟", name = "Bright Star", desc = "Coleção: +600 Stardust", price = 500, stardustGain = 600},
    {emoji = "✨", name = "Magic Dust", desc = "Coleção: +200 Stardust", price = 150, stardustGain = 200},
    {emoji = "🌙", name = "Moon Stone", desc = "Coleção: +1000 Stardust", price = 800, stardustGain = 1000},
    {emoji = "☄️", name = "Comet Tail", desc = "Coleção: +450 Stardust", price = 350, stardustGain = 450}
}

-- ============================================
-- GAMEPASS ITEMS
-- ============================================
Config.GAMEPASS_ITEMS = {
    {emoji = "✨", name = "2x Stardust", desc = "Dobre todo Stardust ganho!", id = 1817317562},
    {emoji = "🐾", name = "3+ Pets", desc = "Equipe até 6 pets de uma vez!", id = 1816119729},
    {emoji = "⭐", name = "2x XP", desc = "Dobre todo XP ganho!", id = 1814337737},
    {emoji = "🔄", name = "Auto Click Star", desc = "AutoClick 2x mais rápido!", id = 1818211451}
}

-- ============================================
-- UPGRADES
-- ============================================
Config.UPGRADES = {
    {emoji = "👆", name = "Click Power", level = 5, desc = "+5% Stardust per click", price = 1200},
    {emoji = "⚡", name = "Super Click", level = 3, desc = "+10% chance for double stardust", price = 2500},
    {emoji = "💫", name = "Star Burst", level = 1, desc = "+15% Stardust from stars", price = 5000},
    {emoji = "🌟", name = "Constellation Bonus", level = 0, desc = "+20% XP from all sources", price = 8000},
    {emoji = "🌙", name = "Moon Power", level = 2, desc = "+8% Stardust at night", price = 3500}
}

-- ============================================
-- EGGS - REBALANCED: Prices use ECONOMY config values
-- ============================================
Config.EGGS = {
    {emoji = "☀️", name = "Ovo da Luz", rarity = "Especial", pets = {"🐉", "🐺", "🦇", "🐔"}, petNames = {"Dragao", "Lobo", "Morcego", "Galinha"}, petRarities = {"Lendario", "Epico", "Raro", "Common"}, price1 = 50, price3 = 120},
    {emoji = "🌙", name = "Ovo Sombrio", rarity = "Especial", pets = {"🔥", "🦉", "🦊", "🐱"}, petNames = {"Fenix", "Coruja", "Raposa", "Gato"}, petRarities = {"Lendario", "Epico", "Raro", "Common"}, price1 = 50, price3 = 120},
    {
        name = "EggCosmic",
        emoji = "🌌",
        rarity = "Lendario",
        starcoinsOnly = true,
        price1Starcoins = 30,
        price3Starcoins = 75,
        pets = {"BabyStar", "GalacticDragon", "GalacticOctopus", "NebulaCreature"},
        petNames = {"Baby Star", "Galactic Dragon", "Galactic Octopus", "Nebula Creature"},
        petRarities = {"Common", "Lendario", "Epico", "Raro"},
    },
    {
        name = "EggLunar",
        emoji = "🌙",
        rarity = "Lendario",
        starcoinsOnly = true,
        price1Starcoins = 30,
        price3Starcoins = 75,
        pets = {"CrystalBear", "LunarGhost", "LunarComet", "LunarPhoenix"},
        petNames = {"Crystal Bear", "Lunar Ghost", "Lunar Comet", "Lunar Phoenix"},
        petRarities = {"Epico", "Common", "Raro", "Lendario"},
    }
}

-- ============================================
-- WORLDS
-- ============================================
Config.WORLDS = {
    {emoji = "🍄", name = "Ilha do Cogumelo", required = 0, desc = "Uma ilha magica cheia de cogumelos", unlocked = true, current = true, teleportPart = "Ilha do Cogumelo Teleport"},
    {emoji = "☄️", name = "Asteroide", required = 50000, desc = "Um campo de asteroides perigoso", unlocked = false, current = false, teleportPart = "Asteroide Teleport"},
    {emoji = "⭐", name = "StarPlace", required = 250000, desc = "O lugar das estrelas brilhantes", unlocked = true, current = false, teleportPart = "StarPlace Teleport"},
    {emoji = "💀", name = "Terra Morta", required = 1000000, desc = "Uma terra abandonada e misteriosa", unlocked = false, current = false, teleportPart = "Terra Morta Teleport"},
    {emoji = "💎", name = "Crystal Tree", required = 0, desc = "Ilha do boss Crystal Tree - acesse livremente!", unlocked = true, current = false, teleportPart = "Teleport Crystal Tree"}
}

-- ============================================
-- QUESTS
-- ============================================
Config.QUESTS = {
    {emoji = "⭐", name = "Star Collector", desc = "Click the star 500 times", progress = 250, goal = 500, reward = "✨ 500", completed = false},
    {emoji = "💫", name = "Shooting Star", desc = "Collect 1000 Stardust", progress = 1000, goal = 1000, reward = "🌟 x1", completed = true},
    {emoji = "🌙", name = "Moon Walker", desc = "Travel to 3 different worlds", progress = 2, goal = 3, reward = "✨ 1000", completed = false},
    {emoji = "🌟", name = "Rising Star", desc = "Reach level 10", progress = 12, goal = 10, reward = "✨ 2500", completed = true},
    {emoji = "✨", name = "Sparkle Master", desc = "Open 10 eggs", progress = 7, goal = 10, reward = "🌟 x2", completed = false},
    {emoji = "🌌", name = "Galaxy Explorer", desc = "Complete 5 daily quests", progress = 3, goal = 5, reward = "✨ 5000", completed = false}
}

-- ============================================
-- DAILY REWARDS - REBALANCED: Reduced scaling for better economy
-- ============================================
Config.DAILY_REWARDS = {
    {emoji = "✨", reward = "100 Stardust"},
    {emoji = "💫", reward = "150 Stardust"},
    {emoji = "🌟", reward = "250 Stardust"},
    {emoji = "🌙", reward = "400 Stardust"},
    {emoji = "⭐", reward = "600 Stardust"},
    {emoji = "🔮", reward = "800 Stardust"},
    {emoji = "🎁", reward = "1200 Stardust"}
}

-- ============================================
-- BUTTONS CONFIG
-- ============================================
Config.BUTTONS = {
    {name = "Shop", panel = "ShopPanel", emoji = "🛒"},
    {name = "Sell", panel = "SellPanel", emoji = "💰"},
    {name = "Upgrades", panel = "UpgradesPanel", emoji = "⚡"},
    {name = "Inventory", panel = "InventoryPanel", emoji = "🎒"},
    {name = "Eggs", panel = "EggsPanel", emoji = "🥚"},
    {name = "Pets", panel = "PetsPanel", emoji = "🐾"},
    {name = "Supernova", panel = "SupernovaPanel", emoji = "💥"},
    {name = "Worlds", panel = "WorldsPanel", emoji = "🌍"},
    {name = "Quests", panel = "QuestsPanel", emoji = "📋"},
    {name = "AutoClick", panel = "AutoClickPanel", emoji = "🔄"},
    {name = "Settings", panel = "SettingsPanel", emoji = "⚙️"},
    {name = "Leaderboard", panel = "LeaderboardPanel", emoji = "🏆"},
    {name = "Trade", panel = "TradePanel", emoji = "🤝"}
}

-- ============================================
-- SUPERNOVA TOKEN SYSTEM
-- ============================================
-- Exclusive pets purchasable with Supernova Tokens
Config.SUPERNOVA_PETS = {
    {id = "NovaDragon", name = "Nova Dragon", emoji = "🐉", rarity = "Supernova", multiplier = 8.0, price = 5, desc = "Dragão nascido das cinzas estelares"},
    {id = "StellarPhoenix", name = "Stellar Phoenix", emoji = "🔥", rarity = "Supernova", multiplier = 10.0, price = 8, desc = "Fênix renascida de uma supernova"},
    {id = "CosmicEmperor", name = "Cosmic Emperor", emoji = "👑", rarity = "Supernova", multiplier = 12.0, price = 12, desc = "O governante supremo do cosmos"}
}

-- Permanent upgrades that persist after Supernova reset
Config.PERMANENT_UPGRADES = {
    {id = "StartBoost", name = "Start Boost", desc = "Comece com +500 Stardust após reset", price = 3, effect = "startStardust", value = 500},
    {id = "XPHeadstart", name = "XP Headstart", desc = "Comece no nível 5 após reset", price = 5, effect = "startLevel", value = 5},
    {id = "TokenBonus", name = "Token Bonus", desc = "+1 Token extra por Supernova", price = 8, effect = "extraTokens", value = 1},
    {id = "MultiplierBoost", name = "Multiplier Boost", desc = "+0.2 multiplicador base permanente", price = 15, effect = "baseMultiplier", value = 0.2}
}

-- Cosmetic titles purchasable with tokens
Config.SUPERNOVA_TITLES = {
    {id = "Starborn", name = "Starborn", emoji = "⭐", price = 3, desc = "Nascido das estrelas"},
    {id = "NovaMaster", name = "Nova Master", emoji = "💥", price = 6, desc = "Mestre das supernovas"},
    {id = "CosmicLord", name = "Cosmic Lord", emoji = "🌌", price = 10, desc = "Senhor do cosmos"},
    {id = "StellarGod", name = "Stellar God", emoji = "👑", price = 20, desc = "Deus estelar supremo"}
}

-- ============================================
-- HELPER FUNCTIONS
-- ============================================
function Config.abbreviateNumber(num)
    if num >= 1e12 then return string.format("%.1fT", num / 1e12)
    elseif num >= 1e9 then return string.format("%.1fB", num / 1e9)
    elseif num >= 1e6 then return string.format("%.1fM", num / 1e6)
    elseif num >= 1e3 then return string.format("%.1fK", num / 1e3)
    else return tostring(math.floor(num)) end
end

return Config