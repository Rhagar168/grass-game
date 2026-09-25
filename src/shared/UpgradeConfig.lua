local UpgradeConfig = {
	-- DAMAGE
	Damage1={Price=3,Requires=nil,FlatDamage=1,Title="Damage I",Description="Increases your cutting damage.",BonusText="+1 Damage"},
	Damage2={Price=20,Requires="Damage1",PercentDamage=.25,Title="Damage II",Description="Increases your cutting damage.",BonusText="+25% Damage"},
	Damage3={Price=70,Requires="Damage2",FlatDamage=2,Title="Damage III",Description="Increases your cutting damage.",BonusText="+2 Damage"},
	Damage4={Price=160,Requires="Damage3",PercentDamage=.25,Title="Damage IV",Description="Increases your cutting damage.",BonusText="+25% Damage"},
	Damage5={Price=420,Requires="Damage4",FlatDamage=3,Title="Damage V",Description="Increases your cutting damage.",BonusText="+3 Damage"},
	Damage6={Price=750,Requires="Damage5",PercentDamage=.30,Title="Damage VI",Description="Increases your cutting damage.",BonusText="+30% Damage"},
	Damage7={Price=1800,Requires="Damage6",FlatDamage=4,Title="Damage VII",Description="Increases your cutting damage.",BonusText="+4 Damage"},
	Damage8={Price=4800,Requires="Damage7",PercentDamage=.35,Title="Damage VIII",Description="Increases your cutting damage.",BonusText="+35% Damage"},
	Damage9={Price=11200,Requires="Damage8",FlatDamage=5,Title="Damage IX",Description="Increases your cutting damage.",BonusText="+5 Damage"},
	Damage10={Price=20000,Requires="Damage9",PercentDamage=.50,Title="Damage X",Description="Massively increases your cutting damage.",BonusText="+50% Damage"},

	-- CUT SPEED
	CutCooldown1={Price=40,Requires="Damage2",CutCooldownReduction=.10,Title="Cut Speed I",Description="Makes your shears cut faster.",BonusText="-10% Cut Cooldown"},
	CutCooldown2={Price=150,Requires="CutCooldown1",CutCooldownReduction=.10,Title="Cut Speed II",Description="Makes your shears cut faster.",BonusText="-10% Cut Cooldown"},
	CutCooldown3={Price=600,Requires="CutCooldown2",CutCooldownReduction=.10,Title="Cut Speed III",Description="Makes your shears cut faster.",BonusText="-10% Cut Cooldown"},
	CutCooldown4={Price=2000,Requires="CutCooldown3",CutCooldownReduction=.10,Title="Cut Speed IV",Description="Makes your shears cut faster.",BonusText="-10% Cut Cooldown"},
	CutCooldown5={Price=9600,Requires="CutCooldown4",CutCooldownReduction=.15,Title="Cut Speed V",Description="Greatly increases your cutting speed.",BonusText="-15% Cut Cooldown"},

	-- CUT COUNT
	CutCount1={Price=75,Requires="Damage3",CutCountBonus=1,Title="Cut Count I",Description="Cut more grass at once.",BonusText="+1 Cut Count"},
	CutCount2={Price=450,Requires="CutCount1",CutCountBonus=1,Title="Cut Count II",Description="Cut more grass at once.",BonusText="+1 Cut Count"},
	CutCount3={Price=1600,Requires="CutCount2",CutCountBonus=1,Title="Cut Count III",Description="Cut more grass at once.",BonusText="+1 Cut Count"},
	CutCount4={Price=5400,Requires="CutCount3",CutCountBonus=2,Title="Cut Count IV",Description="Cut several grass plants at once.",BonusText="+2 Cut Count"},
	CutCount5={Price=16000,Requires="CutCount4",CutCountBonus=3,Title="Cut Count V",Description="Cut many grass plants at once.",BonusText="+3 Cut Count"},

	-- CUT RADIUS
	CutRadius1={Price=60,Requires="CutCooldown2",CutRadiusBonus=1,Title="Cut Radius I",Description="Increases your cutting range.",BonusText="+1 Cut Radius"},
	CutRadius2={Price=200,Requires="CutRadius1",CutRadiusBonus=1,Title="Cut Radius II",Description="Increases your cutting range.",BonusText="+1 Cut Radius"},
	CutRadius3={Price=750,Requires="CutRadius2",CutRadiusBonus=1.5,Title="Cut Radius III",Description="Reach grass from farther away.",BonusText="+1.5 Cut Radius"},
	CutRadius4={Price=3600,Requires="CutRadius3",CutRadiusBonus=2,Title="Cut Radius IV",Description="Greatly increases your cutting range.",BonusText="+2 Cut Radius"},
	CutRadius5={Price=12000,Requires="CutRadius4",CutRadiusBonus=2.5,Title="Cut Radius V",Description="Massively increases your cutting range.",BonusText="+2.5 Cut Radius"},

	-- CRIT
	CritChance1={Price=150,Requires="CutCount2",CritChanceBonus=.05,Title="Crit Chance I",Description="Chance to deal a critical hit.",BonusText="+5% Crit Chance"},
	CritChance2={Price=540,Requires="CritChance1",CritChanceBonus=.05,Title="Crit Chance II",Description="Critical hits happen more often.",BonusText="+5% Crit Chance"},
	CritChance3={Price=1800,Requires="CritChance2",CritChanceBonus=.10,Title="Crit Chance III",Description="Critical hits happen more often.",BonusText="+10% Crit Chance"},
	CritChance4={Price=6000,Requires="CritChance3",CritChanceBonus=.10,Title="Crit Chance IV",Description="Greatly increases critical hit chance.",BonusText="+10% Crit Chance"},
	CritChance5={Price=20000,Requires="CritChance4",CritChanceBonus=.15,Title="Crit Chance V",Description="Massively increases critical hit chance.",BonusText="+15% Crit Chance"},
	CritDamage1={Price=200,Requires="CritChance3",CritDamageBonus=.25,Title="Crit Damage I",Description="Critical hits deal more damage.",BonusText="+25% Crit Damage"},
	CritDamage2={Price=750,Requires="CritDamage1",CritDamageBonus=.25,Title="Crit Damage II",Description="Critical hits deal more damage.",BonusText="+25% Crit Damage"},
	CritDamage3={Price=3600,Requires="CritDamage2",CritDamageBonus=.50,Title="Crit Damage III",Description="Critical hits become much stronger.",BonusText="+50% Crit Damage"},
	CritDamage4={Price=12000,Requires="CritDamage3",CritDamageBonus=.50,Title="Crit Damage IV",Description="Critical hits become much stronger.",BonusText="+50% Crit Damage"},
	CritDamage5={Price=40000,Requires="CritDamage4",CritDamageBonus=1,Title="Crit Damage V",Description="Massively increases critical damage.",BonusText="+100% Crit Damage"},

	-- GRASS
	Grass1={Price=10,Requires="Damage1",PercentGrass=0.15,Title="Grass I",Description="Get more grass from every cut.",BonusText="+15% Grass"},
	Grass2={Price=15,Requires="Grass1",FlatGrass=1,Title="Grass II",Description="Get even more grass from every cut.",BonusText="+1 Grass"},
	Grass3={Price=75,Requires="Grass2",PercentGrass=0.25,Title="Grass III",Description="Greatly increases your grass yield.",BonusText="+25% Grass"},
	Grass4={Price=200,Requires="Grass3",FlatGrass=2,Title="Grass IV",Description="Get more grass from every cut.",BonusText="+2 Grass"},
	Grass5={Price=600,Requires="Grass4",PercentGrass=0.3,Title="Grass V",Description="Increase your grass yield.",BonusText="+30% Grass"},
	Grass6={Price=1600,Requires="Grass5",FlatGrass=3,Title="Grass VI",Description="Get more grass from every cut.",BonusText="+3 Grass"},
	Grass7={Price=4800,Requires="Grass6",PercentGrass=0.4,Title="Grass VII",Description="Greatly increase your grass yield.",BonusText="+40% Grass"},
	Grass8={Price=12800,Requires="Grass7",FlatGrass=4,Title="Grass VIII",Description="Get much more grass from every cut.",BonusText="+4 Grass"},
	Grass9={Price=32000,Requires="Grass8",PercentGrass=0.5,Title="Grass IX",Description="Double your base grass yield again.",BonusText="+50% Grass"},
	Grass10={Price=78000,Requires="Grass9",FlatGrass=6,Title="Grass X",Description="Massively increases grass yield.",BonusText="+6 Grass"},

	-- RARE GRASS
	GoldGrass1={Price=450,Requires="Grass6",GoldGrassChanceBonus=.01,Title="Gold Grass I",Description="Gold grass appears more often.",BonusText="Gold Chance: 2%"},
	GoldGrass2={Price=1400,Requires="GoldGrass1",GoldGrassChanceBonus=.015,Title="Gold Grass II",Description="Gold grass appears more often.",BonusText="Gold Chance: 3.5%"},
	GoldGrass3={Price=4800,Requires="GoldGrass2",GoldGrassChanceBonus=.015,Title="Gold Grass III",Description="Gold grass appears more often.",BonusText="Gold Chance: 5%"},
	GoldGrass4={Price=14400,Requires="GoldGrass3",GoldGrassChanceBonus=.025,Title="Gold Grass IV",Description="Gold grass becomes much more common.",BonusText="Gold Chance: 7.5%"},
	GoldGrass5={Price=40000,Requires="GoldGrass4",GoldGrassChanceBonus=.025,Title="Gold Grass V",Description="Maximize your gold grass chance.",BonusText="Gold Chance: 10%"},
	GoldGrassMultiplier1={Price=4200,Requires="GoldGrass2",GoldGrassMultiplierBonus=.5,Title="Gold Value I",Description="Gold grass gives a bigger reward.",BonusText="Gold Reward: 2.5x"},
	GoldGrassMultiplier2={Price=14400,Requires="GoldGrassMultiplier1",GoldGrassMultiplierBonus=.5,Title="Gold Value II",Description="Gold grass gives a bigger reward.",BonusText="Gold Reward: 3x"},
	GoldGrassMultiplier3={Price=50000,Requires="GoldGrassMultiplier2",GoldGrassMultiplierBonus=1,Title="Gold Value III",Description="Greatly increases gold grass rewards.",BonusText="Gold Reward: 4x"},
	RainbowGrass1={Price=2000,Requires="Grass7",RainbowGrassChanceBonus=.001,Title="Rainbow Grass I",Description="Rainbow grass appears more often.",BonusText="Rainbow Chance: 0.2%"},
	RainbowGrass2={Price=9600,Requires="RainbowGrass1",RainbowGrassChanceBonus=.0015,Title="Rainbow Grass II",Description="Rainbow grass appears more often.",BonusText="Rainbow Chance: 0.35%"},
	RainbowGrass3={Price=28000,Requires="RainbowGrass2",RainbowGrassChanceBonus=.0015,Title="Rainbow Grass III",Description="Rainbow grass appears more often.",BonusText="Rainbow Chance: 0.5%"},
	RainbowGrass4={Price=78000,Requires="RainbowGrass3",RainbowGrassChanceBonus=.0025,Title="Rainbow Grass IV",Description="Rainbow grass becomes much more common.",BonusText="Rainbow Chance: 0.75%"},
	RainbowGrass5={Price=225000,Requires="RainbowGrass4",RainbowGrassChanceBonus=.0025,Title="Rainbow Grass V",Description="Maximize your rainbow grass chance.",BonusText="Rainbow Chance: 1%"},
	RainbowGrassMultiplier1={Price=20000,Requires="RainbowGrass2",RainbowGrassMultiplierBonus=1,Title="Rainbow Value I",Description="Rainbow grass gives a bigger reward.",BonusText="Rainbow Reward: 6x"},
	RainbowGrassMultiplier2={Price=84000,Requires="RainbowGrassMultiplier1",RainbowGrassMultiplierBonus=1.5,Title="Rainbow Value II",Description="Rainbow grass gives a bigger reward.",BonusText="Rainbow Reward: 7.5x"},
	RainbowGrassMultiplier3={Price=270000,Requires="RainbowGrassMultiplier2",RainbowGrassMultiplierBonus=2.5,Title="Rainbow Value III",Description="Massively increases rainbow grass rewards.",BonusText="Rainbow Reward: 10x"},

	-- YELLOW / MONEY BRANCH
	Coins1={Price=20,Requires="Grass2",PercentCoins=0.08,Title="Coins I",Description="Earn more coins when selling grass.",BonusText="+8% Coins"},
	Coins2={Price=75,Requires="Coins1",PercentCoins=0.1,Title="Coins II",Description="Earn more coins when selling grass.",BonusText="+10% Coins"},
	Coins3={Price=360,Requires="Coins2",PercentCoins=0.12,Title="Coins III",Description="Earn more coins when selling grass.",BonusText="+12% Coins"},
	Coins4={Price=750,Requires="Coins3",PercentCoins=0.15,Title="Coins IV",Description="Earn more coins when selling grass.",BonusText="+15% Coins"},
	Coins5={Price=2000,Requires="Coins4",PercentCoins=0.18,Title="Coins V",Description="Earn more coins when selling grass.",BonusText="+18% Coins"},
	Coins6={Price=6000,Requires="Coins5",PercentCoins=0.2,Title="Coins VI",Description="Earn more coins when selling grass.",BonusText="+20% Coins"},
	Coins7={Price=17600,Requires="Coins6",PercentCoins=0.22,Title="Coins VII",Description="Greatly increases selling value.",BonusText="+22% Coins"},
	Coins8={Price=48000,Requires="Coins7",PercentCoins=0.25,Title="Coins VIII",Description="Greatly increases selling value.",BonusText="+25% Coins"},
	Coins9={Price=120000,Requires="Coins8",PercentCoins=0.3,Title="Coins IX",Description="Massively increases selling value.",BonusText="+30% Coins"},
	Coins10={Price=330000,Requires="Coins9",PercentCoins=0.35,Title="Coins X",Description="Massively increases selling value.",BonusText="+35% Coins"},
	InstantBreak1={Price=2000,Requires="Coins8",InstantBreakChance=.05,Title="Instant Break I",Description="Chance to instantly destroy grass on hit.",BonusText="5% Instant Break"},
	InstantBreak2={Price=14400,Requires="InstantBreak1",InstantBreakChance=.05,Title="Instant Break II",Description="Increase instant break chance.",BonusText="10% Instant Break"},
	InstantBreak3={Price=72000,Requires="InstantBreak2",InstantBreakChance=.05,Title="Instant Break III",Description="Increase instant break chance.",BonusText="15% Instant Break"},
	SellMultiplier1={Price=5400,Requires="Coins6",SellMultiplierBonus=0.15,Title="Sell Multiplier I",Description="Multiply all coin value from grass.",BonusText="1.15x Sell Value"},
	SellMultiplier2={Price=35000,Requires="SellMultiplier1",SellMultiplierBonus=0.15,Title="Sell Multiplier II",Description="Multiply all coin value from grass.",BonusText="1.3x Sell Value"},
	SellMultiplier3={Price=180000,Requires="SellMultiplier2",SellMultiplierBonus=0.2,Title="Sell Multiplier III",Description="Massively increase grass sell value.",BonusText="1.5x Sell Value"},
	SellMultiplier4={Price=600000,Requires="SellMultiplier3",SellMultiplierBonus=0.25,Title="Sell Multiplier IV",Description="Greatly increase grass sell value.",BonusText="1.75x Sell Value"},
	SellMultiplier5={Price=1400000,Requires="SellMultiplier4",SellMultiplierBonus=0.25,Title="Sell Multiplier V",Description="Massively increase grass sell value.",BonusText="2x Sell Value"},

	-- BACKPACK
	Backpack1={Price=5,Requires="Damage1",BackpackCapacity=250,Title="Backpack I",Description="Increases your backpack capacity.",BonusText="250 Capacity"},
	Backpack2={Price=60,Requires="Backpack1",BackpackCapacity=1500,Title="Backpack II",Description="Increases your backpack capacity.",BonusText="1.5K Capacity"},
	Backpack3={Price=200,Requires="Backpack2",BackpackCapacity=7500,Title="Backpack III",Description="Increases your backpack capacity.",BonusText="7.5K Capacity"},
	Backpack4={Price=750,Requires="Backpack3",BackpackCapacity=25000,Title="Backpack IV",Description="Increases your backpack capacity.",BonusText="25K Capacity"},
	Backpack5={Price=2000,Requires="Backpack4",BackpackCapacity=75000,Title="Backpack V",Description="Increases your backpack capacity.",BonusText="75K Capacity"},
	Backpack6={Price=6000,Requires="Backpack5",BackpackCapacity=250000,Title="Backpack VI",Description="Increases your backpack capacity.",BonusText="250K Capacity"},
	Backpack7={Price=20000,Requires="Backpack6",BackpackCapacity=1000000,Title="Backpack VII",Description="Increases your backpack capacity.",BonusText="1M Capacity"},
	Backpack8={Price=50000,Requires="Backpack7",BackpackCapacity=4000000,Title="Backpack VIII",Description="Increases your backpack capacity.",BonusText="4M Capacity"},
	Backpack9={Price=180000,Requires="Backpack8",BackpackCapacity=15000000,Title="Backpack IX",Description="Increases your backpack capacity.",BonusText="15M Capacity"},
	Backpack10={Price=375000,Requires="Backpack9",BackpackCapacity=50000000,Title="Backpack X",Description="Massively increases your backpack capacity.",BonusText="50M Capacity"},

	-- INSTANT SELL
	InstantSell1={Price=200,Requires="Backpack3",InstantSellChance=.05,Title="Instant Sell I",Description="Chance to instantly sell grass when cutting.",BonusText="+5% Instant Sell"},
	InstantSell2={Price=1200,Requires="InstantSell1",InstantSellChance=.05,Title="Instant Sell II",Description="Increases your instant sell chance.",BonusText="+5% Instant Sell"},
	InstantSell3={Price=4500,Requires="InstantSell2",InstantSellChance=.05,Title="Instant Sell III",Description="Increases your instant sell chance.",BonusText="+5% Instant Sell"},
	InstantSell4={Price=16000,Requires="InstantSell3",InstantSellChance=.10,Title="Instant Sell IV",Description="Greatly increases instant sell chance.",BonusText="+10% Instant Sell"},
	InstantSell5={Price=50000,Requires="InstantSell4",InstantSellChance=.15,Title="Instant Sell V",Description="Massively increases instant sell chance.",BonusText="+15% Instant Sell"},

	-- WALK SPEED
	WalkSpeed1={Price=75,Requires="Backpack2",WalkSpeedBonus=2,Title="Walk Speed I",Description="Move faster.",BonusText="+2 Walk Speed"},
	WalkSpeed2={Price=450,Requires="WalkSpeed1",WalkSpeedBonus=2,Title="Walk Speed II",Description="Move even faster.",BonusText="+2 Walk Speed"},
	WalkSpeed3={Price=1600,Requires="WalkSpeed2",WalkSpeedBonus=3,Title="Walk Speed III",Description="Greatly increases movement speed.",BonusText="+3 Walk Speed"},
	WalkSpeed4={Price=6000,Requires="WalkSpeed3",WalkSpeedBonus=3,Title="Walk Speed IV",Description="Greatly increases movement speed.",BonusText="+3 Walk Speed"},
	WalkSpeed5={Price=20000,Requires="WalkSpeed4",WalkSpeedBonus=4,Title="Walk Speed V",Description="Massively increases movement speed.",BonusText="+4 Walk Speed"},

	-- XP
	XPBoost1={Price=200,Requires="WalkSpeed2",XPBonus=.10,Title="More XP I",Description="Earn more XP from grass.",BonusText="+10% XP"},
	XPBoost2={Price=750,Requires="XPBoost1",XPBonus=.15,Title="More XP II",Description="Earn even more XP.",BonusText="+15% XP"},
	XPBoost3={Price=3600,Requires="XPBoost2",XPBonus=.20,Title="More XP III",Description="Increase XP gain further.",BonusText="+20% XP"},
	XPBoost4={Price=12000,Requires="XPBoost3",XPBonus=.25,Title="More XP IV",Description="Greatly increases XP gain.",BonusText="+25% XP"},
	XPBoost5={Price=40000,Requires="XPBoost4",XPBonus=.30,Title="More XP V",Description="Massively increases XP gain.",BonusText="+30% XP"},
}

return UpgradeConfig