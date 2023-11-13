--
-- Please see the license file included with this distribution for
-- attribution and copyright information.
--
local applyAttackOriginal;
local modAttackOriginal;
local onPreAttackResolveOriginal;

function onInit()
	onPreAttackResolveOriginal = ActionAttack.onPreAttackResolve;
	ActionAttack.onPreAttackResolve = onPreAttackResolve;

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

function onPreAttackResolve(rSource, rTarget, rRoll, rMessage)
	local sOptionGB = OptionsManager.getOption("GLBL");
	if rRoll.nDefenseVal and sOptionGB == "GlancingBlows" and rRoll.nTotal == rRoll.nDefenseVal then
		rRoll.sResult = "glancing blow";
		for i,sMessage in ipairs(rRoll.aMessages) do
			if sMessage == "[HIT]" then
				rRoll.aMessages[i] = "[GLANCING BLOW]";
				break;
			end
		end
		ActionAttackGB.setGBState(rSource, rTarget);
	end
	onPreAttackResolveOriginal(rSource, rTarget, rRoll, rMessage);
end

-- Don't think this is doing what is intended. It's setting icon and font of message but they are never used
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