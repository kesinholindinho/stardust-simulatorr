local QuestDefinitions = {
	daily = {},
	weekly = {},
	lifetime = {},
}

-- ============================================
-- DAILY QUESTS (reset every day at 00:00 UTC)
-- ============================================

QuestDefinitions.daily[1] = {
	id = "daily_clicks_1000",
	type = "daily",
	name = "Click Starter",
	description = "Make 1,000 clicks today",
	objective = "CLICKS",
	goal = 1000,
	reward = {
		stardust = 50,
		item = nil,
		title = nil,
		multiplier = nil,
	},
	difficulty = "easy",
}

QuestDefinitions.daily[2] = {
	id = "daily_stardust_5000",
	type = "daily",
	name = "Stardust Collector",
	description = "Earn 5,000 Stardust today",
	objective = "STARDUST_EARNED",
	goal = 5000,
	reward = {
		stardust = 100,
		item = nil,
		title = nil,
		multiplier = nil,
	},
	difficulty = "easy",
}

QuestDefinitions.daily[3] = {
	id = "daily_items_used_10",
	type = "daily",
	name = "Item Enthusiast",
	description = "Use or equip items 10 times today",
	objective = "ITEMS_USED",
	goal = 10,
	reward = {
		stardust = 80,
		item = nil,
		title = nil,
		multiplier = nil,
	},
	difficulty = "easy",
}

QuestDefinitions.daily[4] = {
	id = "daily_clicks_10000",
	type = "daily",
	name = "Clicking Pro",
	description = "Make 10,000 clicks today",
	objective = "CLICKS",
	goal = 10000,
	reward = {
		stardust = 300,
		item = nil,
		title = nil,
		multiplier = nil,
	},
	difficulty = "medium",
}

QuestDefinitions.daily[5] = {
	id = "daily_stardust_100k",
	type = "daily",
	name = "Stardust Hoarder",
	description = "Earn 100,000 Stardust today",
	objective = "STARDUST_EARNED",
	goal = 100000,
	reward = {
		stardust = 500,
		item = nil,
		title = nil,
		multiplier = nil,
	},
	difficulty = "medium",
}

QuestDefinitions.daily[6] = {
	id = "daily_items_bought_3",
	type = "daily",
	name = "Shopaholic",
	description = "Purchase 3 items from the shop today",
	objective = "ITEMS_BOUGHT",
	goal = 3,
	reward = {
		stardust = 200,
		item = nil,
		title = nil,
		multiplier = nil,
	},
	difficulty = "medium",
}

QuestDefinitions.daily[7] = {
	id = "daily_playtime_30",
	type = "daily",
	name = "Dedicated Player",
	description = "Play for 30 minutes today",
	objective = "PLAYTIME_MINUTES",
	goal = 30,
	reward = {
		stardust = 120,
		item = nil,
		title = nil,
		multiplier = nil,
	},
	difficulty = "easy",
}

QuestDefinitions.daily[8] = {
	id = "daily_cpm_500",
	type = "daily",
	name = "Speed Clicker",
	description = "Reach 500 clicks per minute",
	objective = "CLICKS_PER_MINUTE",
	goal = 500,
	reward = {
		stardust = 800,
		item = nil,
		title = nil,
		multiplier = nil,
	},
	difficulty = "hard",
}

-- ============================================
-- WEEKLY QUESTS (reset every Monday at 00:00 UTC)
-- ============================================

QuestDefinitions.weekly[1] = {
	id = "weekly_clicks_100k",
	type = "weekly",
	name = "Weekly Clicker",
	description = "Make 100,000 clicks this week",
	objective = "CLICKS",
	goal = 100000,
	reward = {
		stardust = 2000,
		item = nil,
		title = nil,
		multiplier = nil,
	},
	difficulty = "easy",
}

QuestDefinitions.weekly[2] = {
	id = "weekly_login_streak_5",
	type = "weekly",
	name = "Consistent Player",
	description = "Login 5 days in a row this week",
	objective = "LOGIN_STREAK",
	goal = 5,
	reward = {
		stardust = 5000,
		item = nil,
		title = nil,
		multiplier = nil,
	},
	difficulty = "medium",
}

QuestDefinitions.weekly[3] = {
	id = "weekly_items_used_5",
	type = "weekly",
	name = "Item User",
	description = "Use or equip items 5 times this week",
	objective = "ITEMS_USED",
	goal = 5,
	reward = {
		stardust = 1500,
		item = nil,
		title = nil,
		multiplier = nil,
	},
	difficulty = "easy",
}

QuestDefinitions.weekly[4] = {
	id = "weekly_levels_3",
	type = "weekly",
	name = "Level Up",
	description = "Gain 3 levels this week",
	objective = "LEVELS_GAINED",
	goal = 3,
	reward = {
		stardust = 3000,
		item = nil,
		title = nil,
		multiplier = nil,
	},
	difficulty = "medium",
}

QuestDefinitions.weekly[5] = {
	id = "weekly_stardust_spent_50k",
	type = "weekly",
	name = "Big Spender",
	description = "Spend 50,000 Stardust in the shop this week",
	objective = "STARDUST_SPENT",
	goal = 50000,
	reward = {
		stardust = 10000,
		item = "RandomItem",
		title = nil,
		multiplier = nil,
	},
	difficulty = "hard",
}

QuestDefinitions.weekly[6] = {
	id = "weekly_cpm_1000",
	type = "weekly",
	name = "Click Master",
	description = "Reach 1,000 clicks per minute",
	objective = "CLICKS_PER_MINUTE",
	goal = 1000,
	reward = {
		stardust = 8000,
		item = nil,
		title = nil,
		multiplier = nil,
	},
	difficulty = "hard",
}

QuestDefinitions.weekly[7] = {
	id = "weekly_playtime_60",
	type = "weekly",
	name = "Dedicated Week",
	description = "Play for 60 minutes this week",
	objective = "PLAYTIME_MINUTES",
	goal = 60,
	reward = {
		stardust = 4000,
		item = nil,
		title = nil,
		multiplier = nil,
	},
	difficulty = "medium",
}

-- ============================================
-- LIFETIME QUESTS (never reset, progress accumulates forever)
-- ============================================

QuestDefinitions.lifetime[1] = {
	id = "life_clicks_10k",
	type = "lifetime",
	name = "Beginner Clicker",
	description = "Reach 10,000 lifetime clicks",
	objective = "TOTAL_LIFETIME_CLICKS",
	goal = 10000,
	reward = {
		stardust = 500,
		item = nil,
		title = "Beginner",
		multiplier = nil,
	},
	difficulty = "easy",
}

QuestDefinitions.lifetime[2] = {
	id = "life_clicks_500k",
	type = "lifetime",
	name = "Veteran Clicker",
	description = "Reach 500,000 lifetime clicks",
	objective = "TOTAL_LIFETIME_CLICKS",
	goal = 500000,
	reward = {
		stardust = 5000,
		item = nil,
		title = "Veteran",
		multiplier = nil,
	},
	difficulty = "medium",
}

QuestDefinitions.lifetime[3] = {
	id = "life_clicks_10m",
	type = "lifetime",
	name = "Billionaire Clicker",
	description = "Reach 10,000,000 lifetime clicks",
	objective = "TOTAL_LIFETIME_CLICKS",
	goal = 10000000,
	reward = {
		stardust = 0,
		item = nil,
		title = "Billionaire",
		multiplier = nil,
	},
	difficulty = "hard",
}

QuestDefinitions.lifetime[4] = {
	id = "life_stardust_1b",
	type = "lifetime",
	name = "Stardust Master",
	description = "Earn 1,000,000,000 lifetime Stardust",
	objective = "TOTAL_LIFETIME_STARDUST",
	goal = 1000000000,
	reward = {
		stardust = 0,
		item = "ExclusiveItem",
		title = nil,
		multiplier = nil,
	},
	difficulty = "hard",
}

QuestDefinitions.lifetime[5] = {
	id = "life_level_100",
	type = "lifetime",
	name = "Level Master",
	description = "Reach level 100",
	objective = "LEVEL_REACHED",
	goal = 100,
	reward = {
		stardust = 0,
		item = nil,
		title = nil,
		multiplier = 1.1,
	},
	difficulty = "hard",
}

QuestDefinitions.lifetime[6] = {
	id = "life_login_streak_7",
	type = "lifetime",
	name = "Week Warrior",
	description = "Login 7 days in a row",
	objective = "LOGIN_STREAK",
	goal = 7,
	reward = {
		stardust = 2000,
		item = "WeekItem",
		title = nil,
		multiplier = nil,
	},
	difficulty = "easy",
}

QuestDefinitions.lifetime[7] = {
	id = "life_items_bought_100",
	type = "lifetime",
	name = "Shop Regular",
	description = "Purchase 100 items total",
	objective = "ITEMS_BOUGHT",
	goal = 100,
	reward = {
		stardust = 0,
		item = nil,
		title = "Obsessed Buyer",
		multiplier = nil,
	},
	difficulty = "medium",
}

QuestDefinitions.lifetime[8] = {
	id = "life_all_items",
	type = "lifetime",
	name = "Item Collector",
	description = "Purchase 999 items total",
	objective = "ITEMS_BOUGHT",
	goal = 999,
	reward = {
		stardust = 0,
		item = nil,
		title = "Legendary",
		multiplier = nil,
	},
	difficulty = "hard",
}

return QuestDefinitions

-- PART 1 COMPLETE