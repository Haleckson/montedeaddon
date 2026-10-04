<!-- release metadata --> Current source: 3.3.21; declared interfaces: 16001, 120100, 120000.

# Spellbook Levels skin matching





Choose **View: Match Skin** using the View button in either Spellbook Levels window, or enter `/sbl skin match` (`/sbl style match` also works). The saved preference applies to class spells and professions.





Match Skin uses flat warm-dark panels, thin dark borders, white button labels, and the live spellbook tab font when available, matching Ellesmere's Blizzard window appearance. It works without Ellesmere installed. Availability, learned, and requirement colors remain meaningful.





Use `/sbl skin classic` to return to the style selected before skin matching, or pick Auto, Native, Parchment, or Dark with the View button. Existing preferences are preserved until you select the new mode.





Source, tests, documentation, and release ZIPs belong to the SpellbookLevels project. This feature does not require Forever Talents.





## Current improvements





Class spell/rank logic, profession catalog/state logic, and UI helpers now live in separate modules. Trainer observations store their client build and date. Training tooltips explain reference versus observed data and estimated prices. Confirm Ghost Wolf and future-rank behavior in game across classes before promoting this candidate.



## EllesmereUI appearance

When EllesmereUI is installed, addon windows follow its whole-UI style automatically. The EllesmereUI look uses the public skin API for window chrome, controls and fonts. Forever uses bronze and blue accents; Blizzard and Classic use stock borders. Mixed module styles follow the profile window look; use an explicit override when needed. EllesmereUI third-party skin opt-outs are respected.

Use `/exstyle auto`, `eui`, `forever`, `blizzard`, `classic`, or `original`, then `/reload`. The selection saves independently for every loaded Exordiums addon. Without EllesmereUI, original appearance is preserved. Warm Pause reminder colors and opacity remain user-controlled; its options window matches the suite. New appearance candidates require in-game visual verification.
