# Glancing Blows

## Features

Adds functionality for the Glancing Blows house rule.

Rules as Written: If an attack roll is equal to or greater than a target's AC, the attack is a hit.
Glancing Blows: If an attack roll is greater than a target's AC, the attack is a hit. But if the attack roll *exactly* equals the target's AC, the attack is instead a glancing blow, which means that it does half-damage.

In order to make use of the Glancing Blows houserule, the option must be turned on in the Options menu in your campaign.

![Screenshot of the button for Glancing Blows](https://github.com/ThatDudeThatIsOverThere/File-Holder/blob/main/Readme-Images/Glancing%20Blows%20option.png)

Damage Adjustment Correction: Fantasy Grounds by default displays [RESISTED] if a target takes 0 damage (i.e.: is immune to the damage) and [PARTIALLY RESISTED] if a target takes only part of the damage (e.g. is resistant to the damage).
This makes a certain amount of sense, but doesn't jive with 5e's existing syntax for what "immunities" and "resistances" are; this extension fixes it so that what is displayed makes more sense:
- [RESISTED] The target is resistant to all incoming damage
- [IMMUNE] The target is immune to all incoming damage
- [VULNERABLE] The target is vulnerable to all incoming damage
- [PARTIALLY RESISTED] When being hit with an attack that does more than one type of damage, the target is resistant to at least one damage type, but not all of them.
- [PARTIALLY IMMUNE] When being hit with an attack that does more than one type of damage, the target is immune to at least one damage type, but not all of them.
- [PARTIALLY VULNERABLE] When being hit with an attack that does more than one type of damage, the target is vulnerable to at least one damage type, but not all of them.

## Installation

[Download the Glancing-Blows.ext file](https://github.com/ThatDudeThatIsOverThere/Glancing-Blows/releases) and place it in the extensions folder in the Fantasy Grounds Unity game folder.

You can open the Fantasy Grounds Unity game folder by opening Fantasy Grounds Unity and clicking here. 

![Screenshot of the thing you need to click in Fantasy Grounds Unity](https://github.com/ThatDudeThatIsOverThere/File-Holder/blob/main/Readme-Images/FGU-Folder-Open.png)

If you have Fantasy Grounds Unity open while placing the file, you will need to close and reopen Fantasy Grounds Unity after placing the file in order to use the extension.

## Attribution
SmiteWorks owns rights to code sections copied from their rulesets by permission for Fantasy Grounds community development.
'Fantasy Grounds' is a trademark of SmiteWorks USA, LLC.
'Fantasy Grounds' is Copyright 2004-2022 SmiteWorks USA LLC.
