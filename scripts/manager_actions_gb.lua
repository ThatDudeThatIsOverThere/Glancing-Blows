--
-- Please see the license file included with this distribution for
-- attribution and copyright information.
--

local outputResultOriginal;

function onInit()
	outputResultOriginal = ActionsManager.outputResult;
	ActionsManager.outputResult = outputResult;
end

function outputResult(bTower, rSource, rTarget, rMessageGM, rMessagePlayer)
	if string.match(rMessageGM.text, "%[GLANCING BLOW%]") and string.match(rMessageGM.text, "Attack")  then	
		rMessageGM.icon = "roll_attack_gb";
	end
	outputResultOriginal(bTower, rSource, rTarget, rMessageGM, rMessagePlayer);

end