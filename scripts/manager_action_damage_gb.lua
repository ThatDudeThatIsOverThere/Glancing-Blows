--
-- Please see the license file included with this distribution for
-- attribution and copyright information.
--
local applyDamageOriginal;
local getDamageAdjustOriginal;
local setupModRollOriginal;

function onInit()
    applyDamageOriginal = ActionDamage.applyDamage;
    ActionDamage.applyDamage = applyDamage;

    getDamageAdjustOriginal = ActionDamage.getDamageAdjust;
    ActionDamage.getDamageAdjust = getDamageAdjust;

    messageDamageOriginal = ActionDamage.messageDamage;
    ActionDamage.messageDamage = messageDamage;
	
	setupModRollOriginal = ActionDamage.setupModRoll;
	ActionDamage.setupModRoll = setupModRoll;
end

function setupModRoll(rRoll, rSource, rTarget)
	if ActionAttackGB.isGB(rSource, rTarget) then
		rRoll.bGlancing = true;
	end
	setupModRollOriginal(rRoll, rSource, rTarget);
end

function applyDamage(rSource, rTarget, rRoll)
    local sTargetNodeType, nodeTarget = ActorManager.getTypeAndNode(rTarget);
    local nAdjustedDamage = 0;
    if not nodeTarget then
        return;
    end

    local rDamageOutput = ActionDamage.decodeDamageText(rRoll.nTotal, rRoll.sDesc);
    if rRoll then
        rRoll.aDamageTypes = rDamageOutput.aDamageTypes;
    end
    -- make tNotifications into a table
    if not rDamageOutput.tNotifications then
        rDamageOutput.tNotifications = {};
    end
    if (rRoll.sType == 'damage') then
        local nDamageAdjust, bVulnerable, bResist, rGB = getDamageAdjust(rSource, rTarget, rDamageOutput.nVal, rDamageOutput);
        nAdjustedDamage = rDamageOutput.nVal + nDamageAdjust;

        if nAdjustedDamage < 0 then
            nAdjustedDamage = 0;
        end

        if rRoll.bGlancing then
            nAdjustedDamage = math.floor(nAdjustedDamage / 2);
            rRoll.nTotal = nAdjustedDamage;
            rRoll.sDesc = rRoll.sDesc .. '[GLANCING BLOW]';
        end
		
		--Adding some code to update the damage display tags in the chat window so that they conform to 5e conventions
		if (rGB.nDamageTypeCount == rGB.nImmuneCount) then
			rRoll.sDesc = rRoll.sDesc .. '[IMMUNE]';
		end
		if ((rGB.nDamageTypeCount > rGB.nImmuneCount) and (rGB.nImmuneCount > 0)) then
			rRoll.sDesc = rRoll.sDesc .. '[PARTIALLY IMMUNE]';
		end

		if (rGB.nDamageTypeCount == rGB.nResistCount) then
			rRoll.sDesc = rRoll.sDesc .. '[RESISTED]';
		end
		if ((rGB.nDamageTypeCount > rGB.nResistCount) and (rGB.nResistCount > 0)) then
			rRoll.sDesc = rRoll.sDesc .. '[PARTIALLY RESISTED]';
		end


		if (rGB.nDamageTypeCount == rGB.nVulnerableCount) then
			rRoll.sDesc = rRoll.sDesc .. '[VULNERABLE]';
		end
		if ((rGB.nDamageTypeCount > rGB.nVulnerableCount) and (rGB.nVulnerableCount > 0)) then
			rRoll.sDesc = rRoll.sDesc .. '[PARTIALLY VULNERABLE]';
		end

    EffectManager.startDelayedUpdates();

    if (string.match(rRoll.sDesc, '%[GLANCING BLOW%]')) then
        -- Also update the sDesc to get rid of the damage type warning.
        local sNewDesc = '';

        -- finding the start of the sections to be added to sNewDesc and adding everything before that to the base variable.
        local sDescIndex = (tonumber((string.find(rRoll.sDesc, 'TYPE')) - 3))
        sNewDesc = (string.sub(rRoll.sDesc, 1, sDescIndex));

        -- adding a counter to swap between floor and ceil
        local countOddDamageValues = 1;

        local sNewDamageSubTotal = ''; -- Have to declare this up here to fix the nil problem
        local otherTags = '';
        local _, tagIndex = string.find(rRoll.sDesc, '%[GLANCING BLOW%]');
        otherTags = string.sub(rRoll.sDesc, tagIndex + 1);
		local _, preTagIndex = string.find(rRoll.sDesc, '.*%)%]');
		local preTags = '';
		if (preTagIndex) then
			preTags = string.sub(rRoll.sDesc, preTagIndex + 1, tagIndex);
		end

        for sDamageType, sDamageDice, sDamageSubTotal in string.gmatch(rRoll.sDesc, '%[TYPE: ([^(]*) %(([%d%+%-dD]+)%=(%d+)%)%]') do
            if (((countOddDamageValues % 2) == 1) and ((tonumber(sDamageSubTotal) % 2) == 1)) then
                sNewDamageSubTotal = tostring(math.floor(tonumber(sDamageSubTotal) / 2));
                countOddDamageValues = countOddDamageValues + 1;
            elseif (((countOddDamageValues % 2) == 0) and ((tonumber(sDamageSubTotal) % 2) == 1)) then
                sNewDamageSubTotal = tostring(math.ceil(tonumber(sDamageSubTotal) / 2));
                countOddDamageValues = countOddDamageValues + 1;
            else
                sNewDamageSubTotal = tostring(math.floor(tonumber(sDamageSubTotal) / 2));
            end

            sNewDesc = sNewDesc .. ' ' .. '[TYPE: ' .. sDamageType .. '(' .. sDamageDice .. ' halved =' .. tostring(sNewDamageSubTotal) .. ')]'; -- not sure if this tostring should stay. Currently nothing bad happens if nil, was breaking for me without it when nil even though it exists on 98 and 100
        end

        sNewDesc = sNewDesc .. ' ' .. '[GLANCING BLOW]' .. otherTags .. preTags;

        rRoll.sDesc = sNewDesc;
    end

    applyDamageOriginal(rSource, rTarget, rRoll);
    EffectManager.endDelayedUpdates();
end

function getDamageAdjust(rSource, rTarget, nDamage, rDamageOutput)
    local nDamageTypeCount = 0;
    -- Get damage adjustment effects
    local aVuln = ActorManager5E.getDamageVulnerabilities(rTarget, rSource);
    local aResist = ActorManager5E.getDamageResistances(rTarget, rSource);
    local aImmune = ActorManager5E.getDamageImmunities(rTarget, rSource);

    local nDamageAdjust, bVulnerable, bResist = getDamageAdjustOriginal(rSource, rTarget, nDamage, rDamageOutput);

    local rGB = {bImmune = false, nImmuneCount = 0, nResistCount = 0, nVulnerableCount = 0};

    for k, v in pairs(rDamageOutput.aDamageTypes) do
        -- Get individual damage types for each damage clause
        local aSrcDmgClauseTypes = {};
        local aTemp = StringManager.split(k, ',', true);
        for _, vType in ipairs(aTemp) do
            if vType ~= 'untyped' and vType ~= '' then
                table.insert(aSrcDmgClauseTypes, vType);
            end
        end

        -- Handle standard immunity, vulnerability and resistance
        local bLocalVulnerable = ActionDamage.checkReductionType(aVuln, aSrcDmgClauseTypes);
        local bLocalResist = ActionDamage.checkReductionType(aResist, aSrcDmgClauseTypes);
        local bLocalImmune = ActionDamage.checkReductionType(aImmune, aSrcDmgClauseTypes);

        -- Calculate adjustment
        -- Vulnerability = double
        -- Resistance = half
        -- Immunity = none
        nDamageTypeCount = nDamageTypeCount + 1;
        if bLocalImmune then
            rGB.bImmune = true;
            rGB.nImmuneCount = rGB.nImmuneCount + 1;
        else
            -- Handle numerical resistance
            local nLocalResist = ActionDamage.checkNumericalReductionType(aResist, aSrcDmgClauseTypes, v);
            if nLocalResist ~= 0 then
                rGB.nResistCount = rGB.nResistCount + 1;
            end
            -- Handle numerical vulnerability
            local nLocalVulnerable = ActionDamage.checkNumericalReductionType(aVuln, aSrcDmgClauseTypes);
            if nLocalVulnerable ~= 0 then
                rGB.nVulnerableCount = rGB.nVulnerableCount + 1;
            end
            -- Handle standard resistance
            if bLocalResist then
                rGB.nResistCount = rGB.nResistCount + 1;
            end
            -- Handle standard vulnerability
            if bLocalVulnerable then
                rGB.nVulnerableCount = rGB.nVulnerableCount + 1;
            end
        end
    end
	
	rGB.nDamageTypeCount = nDamageTypeCount;

    -- Handle damage and mishap threshold
    if (rTarget.sSubtargetPath or '') ~= '' then
        local nDT = DB.getValue(DB.getPath(rTarget.sSubtargetPath, 'damagethreshold'), 0);
        if (nDT > 0) and (nDT > (nDamage + nDamageAdjust)) then
            rGB.bImmune = true;
        end
    else
        local nDT = ActorManager5E.getDamageThreshold(rTarget);
        if (nDT > 0) and (nDT > (nDamage + nDamageAdjust)) then
            rGB.bImmune = true;
        end
    end

    -- Results
    return nDamageAdjust, bVulnerable, bResist, rGB;
end

function messageDamage(rSource, rTarget, rRoll)
    if rRoll.sType == 'damage' then
        if string.match(rRoll.sDesc, '%[GLANCING BLOW%]') then
            rRoll.sResults = rRoll.sResults .. '[GLANCING BLOW] ';
        end
        if string.match(rRoll.sDesc, '%[IMMUNE%]') then
            if string.match(rRoll.sResults, '%[IMMUNE%]') then
                rRoll.sResults = string.gsub(rRoll.sResults, '%[IMMUNE%]', '');
            end
            rRoll.sResults = rRoll.sResults .. '[IMMUNE] ';
        end
        if string.match(rRoll.sDesc, '%[PARTIALLY IMMUNE%]') then
            if string.match(rRoll.sResults, '%[PARTIALLY IMMUNE%]') then
                rRoll.sResults = string.gsub(rRoll.sResults, '%[PARTIALLY IMMUNE%]', '');
            end
            rRoll.sResults = rRoll.sResults .. '[PARTIALLY IMMUNE] ';
        end
        if string.match(rRoll.sDesc, '%[RESISTED%]') then
            if string.match(rRoll.sResults, '%[RESISTED%]') then
                rRoll.sResults = string.gsub(rRoll.sResults, '%[RESISTED%]', '');
            end
            rRoll.sResults = rRoll.sResults .. '[RESISTED] ';
        end
        if string.match(rRoll.sDesc, '%[PARTIALLY RESISTED%]') then
            if string.match(rRoll.sResults, '%[PARTIALLY RESISTED%]') then
                rRoll.sResults = string.gsub(rRoll.sResults, '%[PARTIALLY RESISTED%]', '');
            end
            rRoll.sResults = rRoll.sResults .. '[PARTIALLY RESISTED] ';
        end
        if string.match(rRoll.sDesc, '%[VULNERABLE%]') then
            if string.match(rRoll.sResults, '%[VULNERABLE%]') then
                rRoll.sResults = string.gsub(rRoll.sResults, '%[VULNERABLE%]', '');
            end
            rRoll.sResults = rRoll.sResults .. '[VULNERABLE] ';
        
        elseif string.match(rRoll.sDesc, '%[PARTIALLY VULNERABLE%]') then
            if string.match(rRoll.sResults, '%[PARTIALLY VULNERABLE%]') then
                rRoll.sResults = string.gsub(rRoll.sResults, '%[PARTIALLY VULNERABLE%]', '');
            end
            rRoll.sResults = rRoll.sResults .. '[PARTIALLY VULNERABLE] ';
        end
        if string.sub(rRoll.sResults, 1, 1) == ' ' then
            rRoll.sResults = string.gsub(rRoll.sResults, '%s+', '', 1);
        end
        rRoll.sResults = string.gsub(rRoll.sResults, '%]%s*%[', '] [');
    end
    messageDamageOriginal(rSource, rTarget, rRoll);
end
