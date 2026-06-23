import Foundation

// MARK: - Static Game Data

enum GameData {

    // MARK: Jobs

    static let allJobs: [Job] = [
        Job(id: "fighter", name: "Fighter", lore: "The backbone of every raid party. Masters of blade and shield, Fighters endure where others fall.", emoji: "⚔️",
            baseHP: 1500, baseATK: 150, baseDEF: 120, baseSPD: 80, baseMP: 200,
            startingSkillIDs: ["basic_strike", "shield_bash", "iron_skin"],
            isLocked: false),

        Job(id: "mage", name: "Mage", lore: "Arcane power flows through their veins. A single Mage can level a dungeon floor. Power demands sacrifice.", emoji: "🔮",
            baseHP: 800, baseATK: 220, baseDEF: 60, baseSPD: 90, baseMP: 500,
            startingSkillIDs: ["basic_strike", "fireball", "mana_shield"],
            isLocked: false),

        Job(id: "ranger", name: "Ranger", lore: "Strike from the shadows. Rangers see what others miss — and kill it before it gets close.", emoji: "🏹",
            baseHP: 1000, baseATK: 180, baseDEF: 80, baseSPD: 120, baseMP: 250,
            startingSkillIDs: ["basic_strike", "poison_arrow", "swift_feet"],
            isLocked: false),

        Job(id: "assassin", name: "Assassin", lore: "They don't fight. They execute. An Assassin's blade finds the gap in every defence.", emoji: "🗡️",
            baseHP: 900, baseATK: 200, baseDEF: 70, baseSPD: 140, baseMP: 200,
            startingSkillIDs: ["basic_strike", "backstab", "critical_edge"],
            isLocked: false),

        Job(id: "healer", name: "Healer", lore: "Life and death bow before them. The raid lives only as long as the Healer wills it.", emoji: "💊",
            baseHP: 1100, baseATK: 100, baseDEF: 90, baseSPD: 100, baseMP: 600,
            startingSkillIDs: ["basic_strike", "heal", "regeneration"],
            isLocked: false),

        Job(id: "necromancer", name: "Necromancer", lore: "From the darkness of death, a new army rises. Command shadow soldiers and watch armies crumble.", emoji: "💀",
            baseHP: 1000, baseATK: 170, baseDEF: 80, baseSPD: 90, baseMP: 450,
            startingSkillIDs: ["basic_strike", "shadow_extract", "undying_pact"],
            isLocked: true),
    ]

    static func job(id: String) -> Job? { allJobs.first { $0.id == id } }

    // MARK: Skills

    static let allSkills: [Skill] = [
        // E Rank
        Skill(id: "basic_strike", name: "Basic Strike", description: "A focused physical blow.", emoji: "👊", rarity: .e, mpCost: 0, cooldownTurns: 0, effect: .damage, damageMultiplier: 1.2, healPercent: 0, buffKey: nil, buffValue: 0, buffDuration: 0),
        Skill(id: "defend", name: "Defend", description: "Brace for impact, reducing incoming damage by 30%.", emoji: "🛡️", rarity: .e, mpCost: 20, cooldownTurns: 2, effect: .shield, damageMultiplier: 0, healPercent: 0, buffKey: "defense_boost", buffValue: 0.3, buffDuration: 1),
        Skill(id: "focus", name: "Focus", description: "Concentrate power — next attack deals 50% more damage.", emoji: "🎯", rarity: .e, mpCost: 15, cooldownTurns: 2, effect: .buff, damageMultiplier: 0, healPercent: 0, buffKey: "atk_boost", buffValue: 0.5, buffDuration: 1),

        // D Rank
        Skill(id: "shield_bash", name: "Shield Bash", description: "Strike with your shield, dealing 1.5× damage and stunning for 1 turn.", emoji: "💥", rarity: .d, mpCost: 30, cooldownTurns: 3, effect: .damage, damageMultiplier: 1.5, healPercent: 0, buffKey: "stun", buffValue: 1, buffDuration: 1),
        Skill(id: "fireball", name: "Fireball", description: "Hurl a blazing sphere of arcane fire for 2× magic damage.", emoji: "🔥", rarity: .d, mpCost: 50, cooldownTurns: 3, effect: .damage, damageMultiplier: 2.0, healPercent: 0, buffKey: nil, buffValue: 0, buffDuration: 0),
        Skill(id: "poison_arrow", name: "Poison Arrow", description: "Pierce with a venomous arrow — 1.3× damage + poison (20 dmg/turn × 3).", emoji: "🏹", rarity: .d, mpCost: 35, cooldownTurns: 3, effect: .debuff, damageMultiplier: 1.3, healPercent: 0, buffKey: "poison", buffValue: 20, buffDuration: 3),

        // C Rank
        Skill(id: "war_cry", name: "War Cry", description: "Roar of a veteran hunter — all damage +30% for 3 turns.", emoji: "📣", rarity: .c, mpCost: 40, cooldownTurns: 5, effect: .buff, damageMultiplier: 0, healPercent: 0, buffKey: "atk_boost", buffValue: 0.3, buffDuration: 3),
        Skill(id: "chain_lightning", name: "Chain Lightning", description: "Arc of lightning leaps between foes — 2.5× magic damage.", emoji: "⚡", rarity: .c, mpCost: 80, cooldownTurns: 4, effect: .damage, damageMultiplier: 2.5, healPercent: 0, buffKey: nil, buffValue: 0, buffDuration: 0),
        Skill(id: "backstab", name: "Backstab", description: "Strike the vital point — 3× guaranteed critical damage.", emoji: "🗡️", rarity: .c, mpCost: 60, cooldownTurns: 4, effect: .damage, damageMultiplier: 3.0, healPercent: 0, buffKey: nil, buffValue: 0, buffDuration: 0),
        Skill(id: "heal", name: "Heal", description: "Channel healing light to restore 40% of maximum HP.", emoji: "💚", rarity: .c, mpCost: 70, cooldownTurns: 4, effect: .healing, damageMultiplier: 0, healPercent: 0.4, buffKey: nil, buffValue: 0, buffDuration: 0),

        // B Rank
        Skill(id: "berserk_mode", name: "Berserk Mode", description: "Unleash fury — ATK ×2 but DEF halved for 4 turns.", emoji: "🔴", rarity: .b, mpCost: 100, cooldownTurns: 8, effect: .buff, damageMultiplier: 0, healPercent: 0, buffKey: "berserk", buffValue: 2.0, buffDuration: 4),
        Skill(id: "eagle_eye", name: "Eagle Eye", description: "Sharpen perception — next 3 attacks deal 2× damage.", emoji: "🦅", rarity: .b, mpCost: 80, cooldownTurns: 6, effect: .buff, damageMultiplier: 0, healPercent: 0, buffKey: "atk_boost", buffValue: 1.0, buffDuration: 3),
        Skill(id: "meteor", name: "Meteor", description: "Call down stellar devastation — 4× magic damage to all.", emoji: "☄️", rarity: .b, mpCost: 150, cooldownTurns: 8, effect: .damage, damageMultiplier: 4.0, healPercent: 0, buffKey: nil, buffValue: 0, buffDuration: 0),
        Skill(id: "barrier", name: "Barrier", description: "Erect a divine shield — block 50% damage for 2 turns.", emoji: "🔵", rarity: .b, mpCost: 90, cooldownTurns: 6, effect: .shield, damageMultiplier: 0, healPercent: 0, buffKey: "barrier", buffValue: 0.5, buffDuration: 2),

        // A Rank
        Skill(id: "death_mark", name: "Death Mark", description: "Brand the enemy — target takes 50% extra damage for 5 turns.", emoji: "💀", rarity: .a, mpCost: 120, cooldownTurns: 7, effect: .debuff, damageMultiplier: 0, healPercent: 0, buffKey: "death_mark", buffValue: 0.5, buffDuration: 5),
        Skill(id: "holy_light", name: "Holy Light", description: "Radiant divine energy — restore 60% HP and cleanse all debuffs.", emoji: "✨", rarity: .a, mpCost: 130, cooldownTurns: 8, effect: .healing, damageMultiplier: 0, healPercent: 0.6, buffKey: "cleanse", buffValue: 1, buffDuration: 1),
        Skill(id: "shadow_strike", name: "Shadow Strike", description: "Phase through reality and strike — 5× damage, ignores DEF.", emoji: "🌑", rarity: .a, mpCost: 140, cooldownTurns: 10, effect: .damage, damageMultiplier: 5.0, healPercent: 0, buffKey: "ignore_def", buffValue: 1, buffDuration: 1),

        // S Rank
        Skill(id: "army_of_dead", name: "Army of the Dead", description: "Raise 3 shadow soldiers who each attack for 20 ATK over 3 turns.", emoji: "👥", rarity: .s, mpCost: 200, cooldownTurns: 12, effect: .summon, damageMultiplier: 0, healPercent: 0, buffKey: "summon_shadows", buffValue: 3, buffDuration: 3),
        Skill(id: "absolute_zero", name: "Absolute Zero", description: "Freeze all in eternal winter — 6× magic damage, enemies frozen 2 turns.", emoji: "❄️", rarity: .s, mpCost: 220, cooldownTurns: 15, effect: .damage, damageMultiplier: 6.0, healPercent: 0, buffKey: "freeze", buffValue: 2, buffDuration: 2),

        // SS Rank
        Skill(id: "monarchs_domain", name: "Monarch's Domain", description: "The Shadow Monarch awakens — 10× damage + ATK doubled for 5 turns.", emoji: "👑", rarity: .ss, mpCost: 300, cooldownTurns: 20, effect: .damage, damageMultiplier: 10.0, healPercent: 0, buffKey: "monarch", buffValue: 2.0, buffDuration: 5),

        // Passives
        Skill(id: "iron_skin", name: "Iron Skin", description: "Passive: +15% physical damage reduction permanently.", emoji: "🔗", rarity: .d, mpCost: 0, cooldownTurns: 0, effect: .shield, damageMultiplier: 0, healPercent: 0, buffKey: "passive_def", buffValue: 0.15, buffDuration: -1),
        Skill(id: "mana_shield", name: "Mana Shield", description: "Passive: Convert 10 MP to absorb damage before HP drops.", emoji: "🔮", rarity: .d, mpCost: 0, cooldownTurns: 0, effect: .shield, damageMultiplier: 0, healPercent: 0, buffKey: "passive_mana_shield", buffValue: 10, buffDuration: -1),
        Skill(id: "swift_feet", name: "Swift Feet", description: "Passive: +20 SPD and first attack each battle is free.", emoji: "💨", rarity: .d, mpCost: 0, cooldownTurns: 0, effect: .buff, damageMultiplier: 0, healPercent: 0, buffKey: "passive_spd", buffValue: 20, buffDuration: -1),
        Skill(id: "critical_edge", name: "Critical Edge", description: "Passive: +10% base critical chance on all attacks.", emoji: "⚡", rarity: .d, mpCost: 0, cooldownTurns: 0, effect: .buff, damageMultiplier: 0, healPercent: 0, buffKey: "passive_crit", buffValue: 0.1, buffDuration: -1),
        Skill(id: "regeneration", name: "Regeneration", description: "Passive: Restore 2% max HP at the start of each turn.", emoji: "🌿", rarity: .c, mpCost: 0, cooldownTurns: 0, effect: .healing, damageMultiplier: 0, healPercent: 0.02, buffKey: "passive_regen", buffValue: 0.02, buffDuration: -1),
        Skill(id: "shadow_extract", name: "Shadow Extract", description: "Passive: 50% chance to extract a defeated enemy as a shadow soldier.", emoji: "🌙", rarity: .c, mpCost: 0, cooldownTurns: 0, effect: .summon, damageMultiplier: 0, healPercent: 0, buffKey: "passive_extract", buffValue: 0.5, buffDuration: -1),
        Skill(id: "undying_pact", name: "Undying Pact", description: "Passive: Once per dungeon, auto-revive at 20% HP when defeated.", emoji: "💜", rarity: .b, mpCost: 0, cooldownTurns: 0, effect: .shield, damageMultiplier: 0, healPercent: 0.2, buffKey: "passive_revive", buffValue: 1, buffDuration: -1),
    ]

    static func skill(id: String) -> Skill? { allSkills.first { $0.id == id } }

    // MARK: Weapons

    static let allWeapons: [Weapon] = [
        // E Rank
        Weapon(id: "iron_sword", name: "Iron Sword", description: "Standard issue. Reliable, if unimpressive.", emoji: "🗡️", rarity: .e, baseATKBonus: 20, defBonus: 0, mpBonus: 0, critChanceBonus: 0, critDamageBonus: 0, specialEffect: nil),
        Weapon(id: "oak_staff", name: "Oak Staff", description: "A mage's first wand. Channels mana with ease.", emoji: "🪄", rarity: .e, baseATKBonus: 15, defBonus: 0, mpBonus: 30, critChanceBonus: 0, critDamageBonus: 0, specialEffect: nil),

        // D Rank
        Weapon(id: "hunting_bow", name: "Hunting Bow", description: "Quick release, accurate over distance.", emoji: "🏹", rarity: .d, baseATKBonus: 18, defBonus: 0, mpBonus: 0, critChanceBonus: 0.05, critDamageBonus: 0, specialEffect: "+10% attack speed"),
        Weapon(id: "shadow_dagger", name: "Shadow Dagger", description: "Forged in the shadows of a D-rank gate.", emoji: "🔪", rarity: .d, baseATKBonus: 16, defBonus: 0, mpBonus: 0, critChanceBonus: 0.08, critDamageBonus: 0.1, specialEffect: "+8% critical chance"),

        // C Rank
        Weapon(id: "knights_longsword", name: "Knight's Longsword", description: "A knight's pride — balanced between offence and defence.", emoji: "⚔️", rarity: .c, baseATKBonus: 45, defBonus: 20, mpBonus: 0, critChanceBonus: 0, critDamageBonus: 0, specialEffect: "+20 DEF"),
        Weapon(id: "archmage_wand", name: "Archmage's Wand", description: "Focuses arcane energy with unparalleled precision.", emoji: "✨", rarity: .c, baseATKBonus: 35, defBonus: 0, mpBonus: 100, critChanceBonus: 0, critDamageBonus: 0, specialEffect: "Magic skills +20%"),

        // B Rank
        Weapon(id: "elven_shortbow", name: "Elven Shortbow", description: "Enchanted by ancient elven artificers for hunters.", emoji: "🌿", rarity: .b, baseATKBonus: 40, defBonus: 0, mpBonus: 0, critChanceBonus: 0.1, critDamageBonus: 0.15, specialEffect: "First skill each battle costs no MP"),
        Weapon(id: "dark_blade", name: "Dark Blade", description: "Drinks in shadow energy with each swing.", emoji: "🌑", rarity: .b, baseATKBonus: 50, defBonus: 0, mpBonus: 0, critChanceBonus: 0.05, critDamageBonus: 0.3, specialEffect: "+30% critical damage"),

        // A Rank
        Weapon(id: "holy_avenger", name: "Holy Avenger", description: "Sacred blade forged in divine fire. Heals on kill.", emoji: "⚡", rarity: .a, baseATKBonus: 80, defBonus: 30, mpBonus: 0, critChanceBonus: 0, critDamageBonus: 0, specialEffect: "Restore 5% HP on kill"),
        Weapon(id: "staff_of_calamity", name: "Staff of Calamity", description: "Channels catastrophic arcane potential.", emoji: "🌪️", rarity: .a, baseATKBonus: 70, defBonus: 0, mpBonus: 200, critChanceBonus: 0, critDamageBonus: 0, specialEffect: "AOE skills +50% damage"),

        // S Rank
        Weapon(id: "longinus_spear", name: "Longinus Spear", description: "The legendary spear that pierces any defense.", emoji: "🔱", rarity: .s, baseATKBonus: 90, defBonus: 0, mpBonus: 0, critChanceBonus: 0.05, critDamageBonus: 0.2, specialEffect: "Ignore 30% enemy DEF"),
        Weapon(id: "shadow_monarch_blade", name: "Shadow Monarch's Blade", description: "A blade imbued with the power of the Shadow Monarch.", emoji: "👑", rarity: .s, baseATKBonus: 100, defBonus: 0, mpBonus: 0, critChanceBonus: 0.1, critDamageBonus: 0.25, specialEffect: "+50 ATK when shadow soldiers are active"),

        // SS Rank
        Weapon(id: "absolute_zero_orb", name: "Absolute Zero Orb", description: "Crystallised entropy. Ice stops everything.", emoji: "❄️", rarity: .ss, baseATKBonus: 85, defBonus: 0, mpBonus: 400, critChanceBonus: 0, critDamageBonus: 0, specialEffect: "Ice skills freeze 1 extra turn"),
        Weapon(id: "eternal_darkness_scythe", name: "Eternal Darkness Scythe", description: "Time itself bends to this blade's will.", emoji: "☠️", rarity: .ss, baseATKBonus: 120, defBonus: 0, mpBonus: 0, critChanceBonus: 0.15, critDamageBonus: 0.35, specialEffect: "All skills -50% cooldown"),

        // SSS Rank
        Weapon(id: "ashborns_gift", name: "Ashborn's Gift", description: "The blessing of the God of Death himself. Shadowfire infuses every strike.", emoji: "🌟", rarity: .sss, baseATKBonus: 150, defBonus: 20, mpBonus: 100, critChanceBonus: 0.15, critDamageBonus: 0.5, specialEffect: "All attacks: +20% shadowfire damage"),
    ]

    static func weapon(id: String) -> Weapon? { allWeapons.first { $0.id == id } }

    // MARK: Enemies

    static let allEnemies: [Enemy] = [
        // E-rank
        Enemy(id: "goblin", name: "Goblin", emoji: "👺", dungeonRank: .e, isBoss: false, baseHP: 80, atk: 20, def: 5, xpReward: 20, goldReward: 10),
        Enemy(id: "cave_spider", name: "Cave Spider", emoji: "🕷️", dungeonRank: .e, isBoss: false, baseHP: 60, atk: 15, def: 3, xpReward: 15, goldReward: 8),
        Enemy(id: "giant_rat", name: "Giant Rat", emoji: "🐀", dungeonRank: .e, isBoss: false, baseHP: 100, atk: 18, def: 8, xpReward: 18, goldReward: 9),
        Enemy(id: "goblin_shaman", name: "Goblin Shaman", emoji: "🧙", dungeonRank: .e, isBoss: true, baseHP: 300, atk: 35, def: 15, xpReward: 100, goldReward: 80),

        // D-rank
        Enemy(id: "orc_warrior", name: "Orc Warrior", emoji: "💪", dungeonRank: .d, isBoss: false, baseHP: 200, atk: 50, def: 20, xpReward: 50, goldReward: 30),
        Enemy(id: "dark_elf_archer", name: "Dark Elf Archer", emoji: "🧝", dungeonRank: .d, isBoss: false, baseHP: 150, atk: 45, def: 15, xpReward: 45, goldReward: 25),
        Enemy(id: "stone_golem", name: "Stone Golem", emoji: "🗿", dungeonRank: .d, isBoss: false, baseHP: 350, atk: 40, def: 50, xpReward: 55, goldReward: 35),
        Enemy(id: "orc_chieftain", name: "Orc Chieftain", emoji: "👹", dungeonRank: .d, isBoss: true, baseHP: 800, atk: 70, def: 30, xpReward: 250, goldReward: 200),

        // C-rank
        Enemy(id: "troll", name: "Troll", emoji: "🧌", dungeonRank: .c, isBoss: false, baseHP: 400, atk: 80, def: 35, xpReward: 100, goldReward: 60),
        Enemy(id: "demon_scout", name: "Demon Scout", emoji: "😈", dungeonRank: .c, isBoss: false, baseHP: 300, atk: 90, def: 25, xpReward: 90, goldReward: 55),
        Enemy(id: "dark_shaman", name: "Dark Shaman", emoji: "🧿", dungeonRank: .c, isBoss: false, baseHP: 250, atk: 75, def: 20, xpReward: 85, goldReward: 50),
        Enemy(id: "blood_troll_king", name: "Blood Troll King", emoji: "🩸", dungeonRank: .c, isBoss: true, baseHP: 1500, atk: 100, def: 60, xpReward: 600, goldReward: 500),

        // B-rank
        Enemy(id: "ice_elemental", name: "Ice Elemental", emoji: "🧊", dungeonRank: .b, isBoss: false, baseHP: 500, atk: 120, def: 50, xpReward: 180, goldReward: 100),
        Enemy(id: "fire_drake", name: "Fire Drake", emoji: "🐉", dungeonRank: .b, isBoss: false, baseHP: 600, atk: 130, def: 45, xpReward: 200, goldReward: 120),
        Enemy(id: "shadow_wolf", name: "Shadow Wolf", emoji: "🐺", dungeonRank: .b, isBoss: false, baseHP: 200, atk: 100, def: 30, xpReward: 120, goldReward: 80),
        Enemy(id: "frost_wyvern", name: "Frost Wyvern", emoji: "🦕", dungeonRank: .b, isBoss: true, baseHP: 3000, atk: 150, def: 80, xpReward: 1200, goldReward: 1000),

        // A-rank
        Enemy(id: "undead_knight", name: "Undead Knight", emoji: "⚔️", dungeonRank: .a, isBoss: false, baseHP: 800, atk: 170, def: 100, xpReward: 350, goldReward: 200),
        Enemy(id: "banshee", name: "Banshee", emoji: "👻", dungeonRank: .a, isBoss: false, baseHP: 600, atk: 200, def: 60, xpReward: 380, goldReward: 220),
        Enemy(id: "vampire_lord", name: "Vampire Lord", emoji: "🧛", dungeonRank: .a, isBoss: false, baseHP: 700, atk: 180, def: 80, xpReward: 360, goldReward: 210),
        Enemy(id: "lich_king", name: "Lich King", emoji: "💀", dungeonRank: .a, isBoss: true, baseHP: 6000, atk: 200, def: 120, xpReward: 3000, goldReward: 2500),

        // S-rank
        Enemy(id: "demon_general", name: "Demon General", emoji: "😤", dungeonRank: .s, isBoss: false, baseHP: 1200, atk: 250, def: 150, xpReward: 700, goldReward: 400),
        Enemy(id: "ancient_dragon", name: "Ancient Dragon", emoji: "🐲", dungeonRank: .s, isBoss: false, baseHP: 2000, atk: 280, def: 130, xpReward: 800, goldReward: 500),
        Enemy(id: "chaos_titan", name: "Chaos Titan", emoji: "🌪️", dungeonRank: .s, isBoss: false, baseHP: 1800, atk: 220, def: 200, xpReward: 750, goldReward: 450),
        Enemy(id: "demon_king_baran", name: "Demon King Baran", emoji: "👿", dungeonRank: .s, isBoss: true, baseHP: 15000, atk: 300, def: 180, xpReward: 8000, goldReward: 7000),

        // SS-rank
        Enemy(id: "rulers_vessel", name: "Ruler's Vessel", emoji: "🔮", dungeonRank: .ss, isBoss: false, baseHP: 2500, atk: 350, def: 200, xpReward: 1500, goldReward: 1000),
        Enemy(id: "kamish_wolf", name: "Kamish (Wolf Form)", emoji: "🐺", dungeonRank: .ss, isBoss: false, baseHP: 3000, atk: 400, def: 180, xpReward: 1800, goldReward: 1200),
        Enemy(id: "kamish_dragon", name: "Kamish Dragon God", emoji: "🐲", dungeonRank: .ss, isBoss: true, baseHP: 25000, atk: 400, def: 250, xpReward: 20000, goldReward: 15000),

        // SSS-rank
        Enemy(id: "architects_guardian", name: "Architect's Guardian", emoji: "⚡", dungeonRank: .sss, isBoss: false, baseHP: 5000, atk: 500, def: 300, xpReward: 5000, goldReward: 3000),
        Enemy(id: "the_architect", name: "The Architect", emoji: "✨", dungeonRank: .sss, isBoss: true, baseHP: 50000, atk: 600, def: 350, xpReward: 100000, goldReward: 50000),
    ]

    static func enemies(for rank: DungeonRank) -> [Enemy] { allEnemies.filter { $0.dungeonRank == rank } }
    static func regularEnemies(for rank: DungeonRank) -> [Enemy] { allEnemies.filter { $0.dungeonRank == rank && !$0.isBoss } }
    static func boss(for rank: DungeonRank) -> Enemy? { allEnemies.first { $0.dungeonRank == rank && $0.isBoss } }

    // MARK: Daily Quests

    static func generateDailyQuests() -> [DailyQuest] {
        [
            DailyQuest(id: "daily_dungeons", description: "Clear 3 dungeons", emoji: "🚪", progress: 0, target: 3, goldReward: 200, mcReward: 2),
            DailyQuest(id: "daily_skills", description: "Use skills 10 times", emoji: "✨", progress: 0, target: 10, goldReward: 150, mcReward: 1),
            DailyQuest(id: "daily_bursts", description: "Land 5 Burst Hits", emoji: "💥", progress: 0, target: 5, goldReward: 300, mcReward: 3),
        ]
    }

    // MARK: Gacha Rates

    static func skillGachaPool(pityCount: Int) -> Skill {
        if pityCount >= 79 {
            return allSkills.filter { $0.rarity == .s }.randomElement()!
        }
        let r = Double.random(in: 0..<100)
        let rarity: Rarity
        if r < 40 { rarity = .e }
        else if r < 70 { rarity = .d }
        else if r < 90 { rarity = .c }
        else if r < 98 { rarity = .b }
        else if r < 99.8 { rarity = .a }
        else { rarity = .s }
        let pool = allSkills.filter { $0.rarity == rarity && $0.cooldownTurns > 0 }
        return pool.randomElement() ?? allSkills[0]
    }

    static func weaponGachaPool(pityCount: Int) -> Weapon {
        if pityCount >= 99 {
            return allWeapons.filter { $0.rarity == .s }.randomElement()!
        }
        let r = Double.random(in: 0..<100)
        let rarity: Rarity
        if r < 35 { rarity = .e }
        else if r < 65 { rarity = .d }
        else if r < 85 { rarity = .c }
        else if r < 95 { rarity = .b }
        else if r < 99 { rarity = .a }
        else if r < 99.85 { rarity = .s }
        else if r < 99.95 { rarity = .ss }
        else { rarity = .sss }
        let pool = allWeapons.filter { $0.rarity == rarity }
        return pool.randomElement() ?? allWeapons[0]
    }
}
