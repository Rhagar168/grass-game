local CoreLabConfig = {}

CoreLabConfig.MaxLevel = 5
CoreLabConfig.Costs = {1, 2, 4, 7, 12}

CoreLabConfig.Researches = {
	Power = {DisplayName="Core Power", Attribute="CoreLabPowerLevel", EffectPerLevel=0.05, EffectText="+5% Damage", Times={300,900,1800,3600,7200}},
	Harvest = {DisplayName="Core Harvest", Attribute="CoreLabHarvestLevel", EffectPerLevel=0.05, EffectText="+5% Grass", Times={300,900,1800,3600,7200}},
	Capacity = {DisplayName="Core Capacity", Attribute="CoreLabCapacityLevel", EffectPerLevel=0.10, EffectText="+10% Capacity", Times={600,1200,2700,5400,10800}},
	Wisdom = {DisplayName="Core Wisdom", Attribute="CoreLabWisdomLevel", EffectPerLevel=0.05, EffectText="+5% XP", Times={600,1200,2700,5400,10800}},
	Critical = {DisplayName="Core Critical", Attribute="CoreLabCriticalLevel", EffectPerLevel=0.10, EffectText="+10% Crit Damage", Times={900,1800,3600,7200,14400}},
	BossHunter = {DisplayName="Boss Hunter", Attribute="CoreLabBossHunterLevel", EffectPerLevel=0.05, EffectText="+5% Boss Damage", Times={1200,2700,5400,10800,21600}},
	Accelerator = {DisplayName="Core Accelerator", Attribute="CoreLabAcceleratorLevel", EffectPerLevel=0.05, EffectText="-5% Boss Cooldown", Costs={2,4,7,12,20}, Times={1200,2700,5400,10800,21600}},
	Extraction = {DisplayName="Core Extraction", Attribute="CoreLabExtractionLevel", EffectPerLevel=1, EffectText="+1 Boss GC", Costs={3,6,12,20,35}, Times={1800,3600,7200,14400,28800}},
}

function CoreLabConfig.GetNextLevelInfo(player, researchId)
	local research = CoreLabConfig.Researches[researchId]
	if not research then return nil end
	local level = math.max(0, math.floor(player:GetAttribute(research.Attribute) or 0))
	if level >= CoreLabConfig.MaxLevel then return nil end
	local nextLevel = level + 1
	local costs = research.Costs or CoreLabConfig.Costs
	return research, nextLevel, costs[nextLevel], research.Times[nextLevel]
end

return CoreLabConfig
