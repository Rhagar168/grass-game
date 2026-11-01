local CoreLabConfig = {}

CoreLabConfig.MaxLevel = 10
CoreLabConfig.Costs = {1, 2, 4, 7, 12, 18, 26, 36, 48, 62}

CoreLabConfig.Researches = {
	Power = {DisplayName="Core Power", Attribute="CoreLabPowerLevel", EffectPerLevel=0.05, EffectText="+5% Damage", Times={60,180,360,600,900,1500,2400,3600,5400,7200}},
	Harvest = {DisplayName="Core Harvest", Attribute="CoreLabHarvestLevel", EffectPerLevel=0.05, EffectText="+5% Grass", Times={60,180,360,600,900,1500,2400,3600,5400,7200}},
	Capacity = {DisplayName="Core Capacity", Attribute="CoreLabCapacityLevel", EffectPerLevel=0.10, EffectText="+10% Capacity", Times={90,240,480,720,1200,1800,2700,4200,6000,9000}},
	Wisdom = {DisplayName="Core Wisdom", Attribute="CoreLabWisdomLevel", EffectPerLevel=0.05, EffectText="+5% XP", Times={90,240,480,720,1200,1800,2700,4200,6000,9000}},
	Critical = {DisplayName="Core Critical", Attribute="CoreLabCriticalLevel", EffectPerLevel=0.10, EffectText="+10% Crit Damage", Times={120,300,600,900,1500,2400,3600,5400,7200,10800}},
	BossHunter = {DisplayName="Boss Hunter", Attribute="CoreLabBossHunterLevel", EffectPerLevel=0.05, EffectText="+5% Boss Damage", Times={180,360,720,1200,1800,3000,4500,6000,9000,10800}},
	Accelerator = {DisplayName="Core Accelerator", Attribute="CoreLabAcceleratorLevel", MaxLevel=5, EffectPerLevel=0.05, EffectText="-5% Boss Cooldown", Costs={2,4,7,12,20}, Times={300,600,1200,2400,4800}},
	Extraction = {DisplayName="Core Extraction", Attribute="CoreLabExtractionLevel", MaxLevel=5, EffectPerLevel=1, EffectText="+1 Boss GC", Costs={3,6,12,20,35}, Times={360,900,1800,3600,7200}},
}

function CoreLabConfig.GetNextLevelInfo(player, researchId)
	local research = CoreLabConfig.Researches[researchId]
	if not research then return nil end
	local level = math.max(0, math.floor(player:GetAttribute(research.Attribute) or 0))
	local maxLevel = research.MaxLevel or CoreLabConfig.MaxLevel
	if level >= maxLevel then return nil end
	local nextLevel = level + 1
	local costs = research.Costs or CoreLabConfig.Costs
	return research, nextLevel, costs[nextLevel], research.Times[nextLevel]
end

return CoreLabConfig
