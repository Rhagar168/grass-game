local UpgradeConfig = {
	-- DAMAGE
	Damage1={Price=3,Requires=nil,FlatDamage=1,Title="Damage I",Description="Increases your cutting damage.",BonusText="+1 Damage"},
	Damage2={Price=20,Requires="Damage1",PercentDamage=.25,Title="Damage II",Description="Increases your cutting damage.",BonusText="+25% Damage"},
	Damage3={Price=45,Requires="Damage2",FlatDamage=2,Title="Damage III",Description="Increases your cutting damage.",BonusText="+2 Damage"},
	Damage4={Price=80,Requires="Damage3",PercentDamage=.25,Title="Damage IV",Description="Increases your cutting damage.",BonusText="+25% Damage"},
	Damage5={Price=140,Requires="Damage4",FlatDamage=3,Title="Damage V",Description="Increases your cutting damage.",BonusText="+3 Damage"},
	Damage6={Price=250,Requires="Damage5",PercentDamage=.30,Title="Damage VI",Description="Increases your cutting damage.",BonusText="+30% Damage"},
	Damage7={Price=450,Requires="Damage6",FlatDamage=4,Title="Damage VII",Description="Increases your cutting damage.",BonusText="+4 Damage"},
	Damage8={Price=800,Requires="Damage7",PercentDamage=.35,Title="Damage VIII",Description="Increases your cutting damage.",BonusText="+35% Damage"},
	Damage9={Price=1400,Requires="Damage8",FlatDamage=5,Title="Damage IX",Description="Increases your cutting damage.",BonusText="+5 Damage"},
	Damage10={Price=2500,Requires="Damage9",PercentDamage=.50,Title="Damage X",Description="Massively increases your cutting damage.",BonusText="+50% Damage"},

	-- CUT SPEED
	CutCooldown1={Price=25,Requires="Damage2",CutCooldownReduction=.10,Title="Cut Speed I",Description="Makes your shears cut faster.",BonusText="-10% Cut Cooldown"},
	CutCooldown2={Price=75,Requires="CutCooldown1",CutCooldownReduction=.10,Title="Cut Speed II",Description="Makes your shears cut faster.",BonusText="-10% Cut Cooldown"},
	CutCooldown3={Price=200,Requires="CutCooldown2",CutCooldownReduction=.10,Title="Cut Speed III",Description="Makes your shears cut faster.",BonusText="-10% Cut Cooldown"},
	CutCooldown4={Price=500,Requires="CutCooldown3",CutCooldownReduction=.10,Title="Cut Speed IV",Description="Makes your shears cut faster.",BonusText="-10% Cut Cooldown"},
	CutCooldown5={Price=1200,Requires="CutCooldown4",CutCooldownReduction=.15,Title="Cut Speed V",Description="Greatly increases your cutting speed.",BonusText="-15% Cut Cooldown"},

	-- CUT COUNT
	CutCount1={Price=50,Requires="Damage3",CutCountBonus=1,Title="Cut Count I",Description="Cut more grass at once.",BonusText="+1 Cut Count"},
	CutCount2={Price=150,Requires="CutCount1",CutCountBonus=1,Title="Cut Count II",Description="Cut more grass at once.",BonusText="+1 Cut Count"},
	CutCount3={Price=400,Requires="CutCount2",CutCountBonus=1,Title="Cut Count III",Description="Cut more grass at once.",BonusText="+1 Cut Count"},
	CutCount4={Price=900,Requires="CutCount3",CutCountBonus=2,Title="Cut Count IV",Description="Cut several grass plants at once.",BonusText="+2 Cut Count"},
	CutCount5={Price=2000,Requires="CutCount4",CutCountBonus=3,Title="Cut Count V",Description="Cut many grass plants at once.",BonusText="+3 Cut Count"},

	-- CUT RADIUS
	CutRadius1={Price=40,Requires="CutCooldown2",CutRadiusBonus=1,Title="Cut Radius I",Description="Increases your cutting range.",BonusText="+1 Cut Radius"},
	CutRadius2={Price=100,Requires="CutRadius1",CutRadiusBonus=1,Title="Cut Radius II",Description="Increases your cutting range.",BonusText="+1 Cut Radius"},
	CutRadius3={Price=250,Requires="CutRadius2",CutRadiusBonus=1.5,Title="Cut Radius III",Description="Reach grass from farther away.",BonusText="+1.5 Cut Radius"},
	CutRadius4={Price=600,Requires="CutRadius3",CutRadiusBonus=2,Title="Cut Radius IV",Description="Greatly increases your cutting range.",BonusText="+2 Cut Radius"},
	CutRadius5={Price=1500,Requires="CutRadius4",CutRadiusBonus=2.5,Title="Cut Radius V",Description="Massively increases your cutting range.",BonusText="+2.5 Cut Radius"},

	-- CRIT
	CritChance1={Price=75,Requires="CutCount2",CritChanceBonus=.05,Title="Crit Chance I",Description="Chance to deal a critical hit.",BonusText="+5% Crit Chance"},
	CritChance2={Price=180,Requires="CritChance1",CritChanceBonus=.05,Title="Crit Chance II",Description="Critical hits happen more often.",BonusText="+5% Crit Chance"},
	CritChance3={Price=450,Requires="CritChance2",CritChanceBonus=.10,Title="Crit Chance III",Description="Critical hits happen more often.",BonusText="+10% Crit Chance"},
	CritChance4={Price=1000,Requires="CritChance3",CritChanceBonus=.10,Title="Crit Chance IV",Description="Greatly increases critical hit chance.",BonusText="+10% Crit Chance"},
	CritChance5={Price=2500,Requires="CritChance4",CritChanceBonus=.15,Title="Crit Chance V",Description="Massively increases critical hit chance.",BonusText="+15% Crit Chance"},
	CritDamage1={Price=100,Requires="CritChance3",CritDamageBonus=.25,Title="Crit Damage I",Description="Critical hits deal more damage.",BonusText="+25% Crit Damage"},
	CritDamage2={Price=250,Requires="CritDamage1",CritDamageBonus=.25,Title="Crit Damage II",Description="Critical hits deal more damage.",BonusText="+25% Crit Damage"},
	CritDamage3={Price=600,Requires="CritDamage2",CritDamageBonus=.50,Title="Crit Damage III",Description="Critical hits become much stronger.",BonusText="+50% Crit Damage"},
	CritDamage4={Price=1500,Requires="CritDamage3",CritDamageBonus=.50,Title="Crit Damage IV",Description="Critical hits become much stronger.",BonusText="+50% Crit Damage"},
	CritDamage5={Price=4000,Requires="CritDamage4",CritDamageBonus=1,Title="Crit Damage V",Description="Massively increases critical damage.",BonusText="+100% Crit Damage"},

	-- GRASS
	Grass1={Price=10,Requires="Damage1",PercentGrass=.25,Title="Grass I",Description="Get more grass from every cut.",BonusText="+25% Grass"},
	Grass2={Price=15,Requires="Grass1",FlatGrass=1,Title="Grass II",Description="Get even more grass from every cut.",BonusText="+1 Grass"},
	Grass3={Price=50,Requires="Grass2",PercentGrass=.50,Title="Grass III",Description="Greatly increases your grass yield.",BonusText="+50% Grass"},
	Grass4={Price=100,Requires="Grass3",FlatGrass=2,Title="Grass IV",Description="Get more grass from every cut.",BonusText="+2 Grass"},
	Grass5={Price=200,Requires="Grass4",PercentGrass=.50,Title="Grass V",Description="Increase your grass yield.",BonusText="+50% Grass"},
	Grass6={Price=400,Requires="Grass5",FlatGrass=3,Title="Grass VI",Description="Get more grass from every cut.",BonusText="+3 Grass"},
	Grass7={Price=800,Requires="Grass6",PercentGrass=.75,Title="Grass VII",Description="Greatly increase your grass yield.",BonusText="+75% Grass"},
	Grass8={Price=1600,Requires="Grass7",FlatGrass=5,Title="Grass VIII",Description="Get much more grass from every cut.",BonusText="+5 Grass"},
	Grass9={Price=3200,Requires="Grass8",PercentGrass=1,Title="Grass IX",Description="Double your base grass yield again.",BonusText="+100% Grass"},
	Grass10={Price=6500,Requires="Grass9",FlatGrass=10,Title="Grass X",Description="Massively increases grass yield.",BonusText="+10 Grass"},

	-- RARE GRASS
	GoldGrass1={Price=150,Requires="Grass6",GoldGrassChanceBonus=.01,Title="Gold Grass I",Description="Gold grass appears more often.",BonusText="Gold Chance: 2%"},
	GoldGrass2={Price=350,Requires="GoldGrass1",GoldGrassChanceBonus=.015,Title="Gold Grass II",Description="Gold grass appears more often.",BonusText="Gold Chance: 3.5%"},
	GoldGrass3={Price=800,Requires="GoldGrass2",GoldGrassChanceBonus=.015,Title="Gold Grass III",Description="Gold grass appears more often.",BonusText="Gold Chance: 5%"},
	GoldGrass4={Price=1800,Requires="GoldGrass3",GoldGrassChanceBonus=.025,Title="Gold Grass IV",Description="Gold grass becomes much more common.",BonusText="Gold Chance: 7.5%"},
	GoldGrass5={Price=4000,Requires="GoldGrass4",GoldGrassChanceBonus=.025,Title="Gold Grass V",Description="Maximize your gold grass chance.",BonusText="Gold Chance: 10%"},
	GoldGrassMultiplier1={Price=700,Requires="GoldGrass2",GoldGrassMultiplierBonus=.5,Title="Gold Value I",Description="Gold grass gives a bigger reward.",BonusText="Gold Reward: 2.5x"},
	GoldGrassMultiplier2={Price=1800,Requires="GoldGrassMultiplier1",GoldGrassMultiplierBonus=.5,Title="Gold Value II",Description="Gold grass gives a bigger reward.",BonusText="Gold Reward: 3x"},
	GoldGrassMultiplier3={Price=5000,Requires="GoldGrassMultiplier2",GoldGrassMultiplierBonus=1,Title="Gold Value III",Description="Greatly increases gold grass rewards.",BonusText="Gold Reward: 4x"},
	RainbowGrass1={Price=500,Requires="Grass7",RainbowGrassChanceBonus=.001,Title="Rainbow Grass I",Description="Rainbow grass appears more often.",BonusText="Rainbow Chance: 0.2%"},
	RainbowGrass2={Price=1200,Requires="RainbowGrass1",RainbowGrassChanceBonus=.0015,Title="Rainbow Grass II",Description="Rainbow grass appears more often.",BonusText="Rainbow Chance: 0.35%"},
	RainbowGrass3={Price=2800,Requires="RainbowGrass2",RainbowGrassChanceBonus=.0015,Title="Rainbow Grass III",Description="Rainbow grass appears more often.",BonusText="Rainbow Chance: 0.5%"},
	RainbowGrass4={Price=6500,Requires="RainbowGrass3",RainbowGrassChanceBonus=.0025,Title="Rainbow Grass IV",Description="Rainbow grass becomes much more common.",BonusText="Rainbow Chance: 0.75%"},
	RainbowGrass5={Price=15000,Requires="RainbowGrass4",RainbowGrassChanceBonus=.0025,Title="Rainbow Grass V",Description="Maximize your rainbow grass chance.",BonusText="Rainbow Chance: 1%"},
	RainbowGrassMultiplier1={Price=2500,Requires="RainbowGrass2",RainbowGrassMultiplierBonus=1,Title="Rainbow Value I",Description="Rainbow grass gives a bigger reward.",BonusText="Rainbow Reward: 6x"},
	RainbowGrassMultiplier2={Price=7000,Requires="RainbowGrassMultiplier1",RainbowGrassMultiplierBonus=1.5,Title="Rainbow Value II",Description="Rainbow grass gives a bigger reward.",BonusText="Rainbow Reward: 7.5x"},
	RainbowGrassMultiplier3={Price=18000,Requires="RainbowGrassMultiplier2",RainbowGrassMultiplierBonus=2.5,Title="Rainbow Value III",Description="Massively increases rainbow grass rewards.",BonusText="Rainbow Reward: 10x"},

	-- YELLOW / MONEY BRANCH
	Coins1={Price=20,Requires="Grass2",PercentCoins=.10,Title="Coins I",Description="Earn more coins when selling grass.",BonusText="+10% Coins"},
	Coins2={Price=50,Requires="Coins1",PercentCoins=.15,Title="Coins II",Description="Earn more coins when selling grass.",BonusText="+15% Coins"},
	Coins3={Price=120,Requires="Coins2",PercentCoins=.20,Title="Coins III",Description="Earn more coins when selling grass.",BonusText="+20% Coins"},
	Coins4={Price=250,Requires="Coins3",PercentCoins=.25,Title="Coins IV",Description="Earn more coins when selling grass.",BonusText="+25% Coins"},
	Coins5={Price=500,Requires="Coins4",PercentCoins=.30,Title="Coins V",Description="Earn more coins when selling grass.",BonusText="+30% Coins"},
	Coins6={Price=1000,Requires="Coins5",PercentCoins=.35,Title="Coins VI",Description="Earn more coins when selling grass.",BonusText="+35% Coins"},
	Coins7={Price=2200,Requires="Coins6",PercentCoins=.40,Title="Coins VII",Description="Greatly increases selling value.",BonusText="+40% Coins"},
	Coins8={Price=4800,Requires="Coins7",PercentCoins=.50,Title="Coins VIII",Description="Greatly increases selling value.",BonusText="+50% Coins"},
	Coins9={Price=10000,Requires="Coins8",PercentCoins=.60,Title="Coins IX",Description="Massively increases selling value.",BonusText="+60% Coins"},
	Coins10={Price=22000,Requires="Coins9",PercentCoins=.75,Title="Coins X",Description="Massively increases selling value.",BonusText="+75% Coins"},
	InstantBreak1={Price=500,Requires="Coins8",InstantBreakChance=.05,Title="Instant Break I",Description="Chance to instantly destroy grass on hit.",BonusText="5% Instant Break"},
	InstantBreak2={Price=1800,Requires="InstantBreak1",InstantBreakChance=.05,Title="Instant Break II",Description="Increase instant break chance.",BonusText="10% Instant Break"},
	InstantBreak3={Price=6000,Requires="InstantBreak2",InstantBreakChance=.05,Title="Instant Break III",Description="Increase instant break chance.",BonusText="15% Instant Break"},
	SellMultiplier1={Price=900,Requires="Coins6",SellMultiplierBonus=.25,Title="Sell Multiplier I",Description="Multiply all coin value from grass.",BonusText="1.25x Sell Value"},
	SellMultiplier2={Price=3500,Requires="SellMultiplier1",SellMultiplierBonus=.25,Title="Sell Multiplier II",Description="Multiply all coin value from grass.",BonusText="1.5x Sell Value"},
	SellMultiplier3={Price=12000,Requires="SellMultiplier2",SellMultiplierBonus=.50,Title="Sell Multiplier III",Description="Massively increase grass sell value.",BonusText="2x Sell Value"},
	SellMultiplier4={Price=30000,Requires="SellMultiplier3",SellMultiplierBonus=.50,Title="Sell Multiplier IV",Description="Greatly increase grass sell value.",BonusText="2.5x Sell Value"},
	SellMultiplier5={Price=70000,Requires="SellMultiplier4",SellMultiplierBonus=.50,Title="Sell Multiplier V",Description="Massively increase grass sell value.",BonusText="3x Sell Value"},

	-- BACKPACK
	Backpack1={Price=5,Requires="Damage1",BackpackCapacity=100,Title="Backpack I",Description="Increases your backpack capacity.",BonusText="100 Capacity"},
	Backpack2={Price=40,Requires="Backpack1",BackpackCapacity=500,Title="Backpack II",Description="Increases your backpack capacity.",BonusText="500 Capacity"},
	Backpack3={Price=100,Requires="Backpack2",BackpackCapacity=2000,Title="Backpack III",Description="Increases your backpack capacity.",BonusText="2K Capacity"},
	Backpack4={Price=250,Requires="Backpack3",BackpackCapacity=5000,Title="Backpack IV",Description="Increases your backpack capacity.",BonusText="5K Capacity"},
	Backpack5={Price=500,Requires="Backpack4",BackpackCapacity=10000,Title="Backpack V",Description="Increases your backpack capacity.",BonusText="10K Capacity"},
	Backpack6={Price=1000,Requires="Backpack5",BackpackCapacity=25000,Title="Backpack VI",Description="Increases your backpack capacity.",BonusText="25K Capacity"},
	Backpack7={Price=2500,Requires="Backpack6",BackpackCapacity=50000,Title="Backpack VII",Description="Increases your backpack capacity.",BonusText="50K Capacity"},
	Backpack8={Price=5000,Requires="Backpack7",BackpackCapacity=100000,Title="Backpack VIII",Description="Increases your backpack capacity.",BonusText="100K Capacity"},
	Backpack9={Price=12000,Requires="Backpack8",BackpackCapacity=250000,Title="Backpack IX",Description="Increases your backpack capacity.",BonusText="250K Capacity"},
	Backpack10={Price=25000,Requires="Backpack9",BackpackCapacity=500000,Title="Backpack X",Description="Massively increases your backpack capacity.",BonusText="500K Capacity"},

	-- INSTANT SELL
	InstantSell1={Price=100,Requires="Backpack3",InstantSellChance=.05,Title="Instant Sell I",Description="Chance to instantly sell grass when cutting.",BonusText="+5% Instant Sell"},
	InstantSell2={Price=300,Requires="InstantSell1",InstantSellChance=.05,Title="Instant Sell II",Description="Increases your instant sell chance.",BonusText="+5% Instant Sell"},
	InstantSell3={Price=750,Requires="InstantSell2",InstantSellChance=.05,Title="Instant Sell III",Description="Increases your instant sell chance.",BonusText="+5% Instant Sell"},
	InstantSell4={Price=2000,Requires="InstantSell3",InstantSellChance=.10,Title="Instant Sell IV",Description="Greatly increases instant sell chance.",BonusText="+10% Instant Sell"},
	InstantSell5={Price=5000,Requires="InstantSell4",InstantSellChance=.15,Title="Instant Sell V",Description="Massively increases instant sell chance.",BonusText="+15% Instant Sell"},

	-- WALK SPEED
	WalkSpeed1={Price=50,Requires="Backpack2",WalkSpeedBonus=2,Title="Walk Speed I",Description="Move faster.",BonusText="+2 Walk Speed"},
	WalkSpeed2={Price=150,Requires="WalkSpeed1",WalkSpeedBonus=2,Title="Walk Speed II",Description="Move even faster.",BonusText="+2 Walk Speed"},
	WalkSpeed3={Price=400,Requires="WalkSpeed2",WalkSpeedBonus=3,Title="Walk Speed III",Description="Greatly increases movement speed.",BonusText="+3 Walk Speed"},
	WalkSpeed4={Price=1000,Requires="WalkSpeed3",WalkSpeedBonus=3,Title="Walk Speed IV",Description="Greatly increases movement speed.",BonusText="+3 Walk Speed"},
	WalkSpeed5={Price=2500,Requires="WalkSpeed4",WalkSpeedBonus=4,Title="Walk Speed V",Description="Massively increases movement speed.",BonusText="+4 Walk Speed"},

	-- XP
	XPBoost1={Price=100,Requires="WalkSpeed2",XPBonus=.10,Title="More XP I",Description="Earn more XP from grass.",BonusText="+10% XP"},
	XPBoost2={Price=250,Requires="XPBoost1",XPBonus=.15,Title="More XP II",Description="Earn even more XP.",BonusText="+15% XP"},
	XPBoost3={Price=600,Requires="XPBoost2",XPBonus=.20,Title="More XP III",Description="Increase XP gain further.",BonusText="+20% XP"},
	XPBoost4={Price=1500,Requires="XPBoost3",XPBonus=.25,Title="More XP IV",Description="Greatly increases XP gain.",BonusText="+25% XP"},
	XPBoost5={Price=4000,Requires="XPBoost4",XPBonus=.30,Title="More XP V",Description="Massively increases XP gain.",BonusText="+30% XP"},
}

return UpgradeConfig