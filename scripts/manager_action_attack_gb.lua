-- 
-- Please see the license file included with this distribution for 
-- attribution and copyright information.
--
local onAttackOriginal;
local applyAttackOriginal;
local modAttackOriginal;
local onAttackResolveOriginal;

function onInit()

	onAttackOriginal = ActionAttack.onAttack;
	ActionAttack.onAttack = onAttack;
	ActionsManager.registerResultHandler("attack", onAttack);
	
	onAttackResolveOriginal = ActionAttack.onAttackResolve;
	ActionAttack.onAttackResolve = onAttackResolve;
	
	applyAttackOriginal = ActionAttack.applyAttack;
	ActionAttack.applyAttack = applyAttack;
	
	modAttackOriginal = ActionAttack.modAttack;
	ActionAttack.modAttack = modAttack;
	ActionsManager.registerModHandler("attack", modAttack);

end

function modAttack(rSource, rTarget, rRoll)
	ActionAttackGB.clearGBState(rSource);
	modAttackOriginal(rSource, rTarget, rRoll);
end

function onAttack(rSource, rTarget, rRoll)
	-- Rebuild detail fields if dragging from chat window
	if not rRoll.nOrder then
		rRoll.nOrder = tonumber(rRoll.sDesc:match("%[ATTACK.*#%d+")) or nil;
	end
	if not rRoll.sRange then
		rRoll.sRange = rRoll.sDesc:match("%[ATTACK.*%((%w+)%)%]");
	end
	if not rRoll.sLabel then
		rRoll.sLabel = StringManager.trim(rRoll.sDesc:match("%[ATTACK.*%]([^%[]+)"));
	end

	ActionsManager2.decodeAdvantage(rRoll);
	
	local sOptionGB = OptionsManager.getOption("GLBL");
	
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.text = rMessage.text:gsub(" %[MOD:[^]]*%]", "");
	
	rRoll.nTotal = ActionsManager.total(rRoll);
	rRoll.aMessages = {};
	
	rRoll.nDefenseVal, rRoll.nAtkEffectsBonus, rRoll.nDefEffectsBonus = ActorManager5E.getDefenseValue(rSource, rTarget, rRoll);
	if rRoll.nAtkEffectsBonus ~= 0 then
		rRoll.nTotal = rRoll.nTotal + rRoll.nAtkEffectsBonus;
		table.insert(rRoll.aMessages, EffectManager.buildEffectOutput(rRoll.nAtkEffectsBonus));
	end
	if rRoll.nDefEffectsBonus ~= 0 then
		rRoll.nDefenseVal = rRoll.nDefenseVal + rRoll.nDefEffectsBonus;
		table.insert(rRoll.aMessages, string.format("[%s %+d]", Interface.getString("effects_def_tag"), rRoll.nDefEffectsBonus));
	end
	
	local sCritThreshold = string.match(rRoll.sDesc, "%[CRIT (%d+)%]");
	local nCritThreshold = tonumber(sCritThreshold) or 20;
	if nCritThreshold < 2 or nCritThreshold > 20 then
		nCritThreshold = 20;
	end
	
	rRoll.nFirstDie = 0;
	if #(rRoll.aDice) > 0 then
		rRoll.nFirstDie = rRoll.aDice[1].result or 0;
	end
	if rRoll.nFirstDie >= nCritThreshold then
		rRoll.bSpecial = true;
		rRoll.sResult = "crit";
		table.insert(rRoll.aMessages, "[CRITICAL HIT]");
	elseif rRoll.nFirstDie == 1 then
		rRoll.sResult = "fumble";
		table.insert(rRoll.aMessages, "[AUTOMATIC MISS]");
	elseif rRoll.nDefenseVal then
		if sOptionGB == "GlancingBlows" and rRoll.nTotal == rRoll.nDefenseVal then
			rRoll.sResult = "glancing blow";
			table.insert(rRoll.aMessages, "[GLANCING BLOW]");
		elseif rRoll.nTotal >= rRoll.nDefenseVal then
			rRoll.sResult = "hit";
			table.insert(rRoll.aMessages, "[HIT]");
		else
			rRoll.sResult = "miss";
			table.insert(rRoll.aMessages, "[MISS]");

		end
	end
	
	if not rTarget then
		rMessage.text = rMessage.text .. " " .. table.concat(rRoll.aMessages, " ");
	end
	
	ActionAttack.onPreAttackResolve(rSource, rTarget, rRoll, rMessage);
	ActionAttackGB.onAttackResolve(rSource, rTarget, rRoll, rMessage);
	ActionAttack.onPostAttackResolve(rSource, rTarget, rRoll, rMessage);
end

function onAttackResolve(rSource, rTarget, rRoll, rMessage)
	-- TRACK GLANCING BLOW STATE
	if rRoll.sResult == "glancing blow" then
		ActionAttackGB.setGBState(rSource, rTarget);
	end
	
	onAttackResolveOriginal(rSource, rTarget, rRoll, rMessage);
end

function applyAttack(rSource, rTarget, rRoll)
	local msgShort = { font = "msgfont" };
	local msgLong = { font = "msgfont" };
	
	if string.match(rRoll.sDesc, "%[GLANCING BLOW%]") then	
		msgLong.icon = "roll_attack_gb";
	end
	
	applyAttackOriginal(rSource, rTarget, rRoll);
end

--
--	GLANCING BLOW STATE TRACKING
--

aGBState = {};

function setGBState(rSource, rTarget)
	local sSourceCT = ActorManager.getCreatureNodeName(rSource);
	if sSourceCT == "" then
		return;
	end
	local sTargetCT = "";
	if rTarget then
		sTargetCT = ActorManager.getCTNodeName(rTarget);
	end
	
	if not aGBState[sSourceCT] then
		aGBState[sSourceCT] = {};
	end
	table.insert(aGBState[sSourceCT], sTargetCT);
end

function clearGBState(rSource)
	local sSourceCT = ActorManager.getCreatureNodeName(rSource);
	if sSourceCT ~= "" then
		aGBState[sSourceCT] = nil;
	end
end

function isGB(rSource, rTarget)
	local sSourceCT = ActorManager.getCreatureNodeName(rSource);
	if sSourceCT == "" then
		return;
	end
	local sTargetCT = "";
	if rTarget then
		sTargetCT = ActorManager.getCTNodeName(rTarget);
	end

	if not aGBState[sSourceCT] then
		return false;
	end
	
	for k,v in ipairs(aGBState[sSourceCT]) do
		if v == sTargetCT then
			table.remove(aGBState[sSourceCT], k);
			return true;
		end
	end
	
	return false;
end