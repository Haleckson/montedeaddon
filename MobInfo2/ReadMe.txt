******************************
***     About MobInfo-2    ***
******************************
MobInfo-2 is a World of Warcraft AddOn that provides you with useful additional 
information about Mobs (ie. opponents/monsters). It adds new information to the 
game's Tooltip whenever you hover with your mouse over a mob. It also adds a 
numeric display of the Mobs health and mana (current and max) to the Mob target 
frame. MobInfo-2 is the continuation of the now abandoned "MobInfo" by
Dizzarian. 

[[ IMPORTANT NOTE FOR DEVELOPERS OF OTHER ADDONS:           ]]
[[ Please read the informatin in "ReadMe_MobInfo_API.txt" ! ]]


*****************************
***     MobInfo-2 Data    ***
*****************************
MobInfo collects data whenever you fight a Mob. It starts off with an empty 
database, which fills up automatically the more you fight and play. The data it 
collects is used for enhancing the game tooltip and the game target frame. It 
is also available to other AddOns.

The MobInfo database is searchable. You can do a search for the most profitable
Mobs. You will find the "Search" button on the "Database" page of the options
dialog.


******************************************
*** Extra Information For Game Tooltip ***
******************************************
The extra information available to show on the game tooltip is:

Class - class of mob
Health - current and total health of the mob
Mana - current and total mana of the mob
Damage - min/max damage range of Mob against you (stored per char)
DPS - your DPS (damage per second) against the Mob (stored per char)
Kills - number of times you have killed the mob (stored per char)
Total Looted - number of times you have looted the mob
Empty Loots - number of times you found empty loot on the mob
XP - actual LAST xp amount you gained from the mob
# to Level - number of kills of this mob neede to gain a level
Quality - the quality of items that are dropped by the mob
Cloth drops - the number of times cloth has dropped on the mob
Avg Coin Drop - average amount of money dropped by the mob
Avg Item Value - average vendor value of items dropped by mob
Total Mob Value - total sum of avg coin drop and avg item value

Note that MobInfo offers a "Combined Mode" where the data of Mobs with the same
name that only differ in level gets combined (added up) into one tooltip. This
mode can be enabled through the options dialog


***************************************
*** Target Frame Health/Mana Values ***
***************************************
MobInfo can display the numeric and percentage values for your current targets
health and mana right on the target frame. This display is highly configurable
through the MobInfo options dialog (position, font, size, etc).


******************************
*** MobInfo Options Dialog ***
******************************
Type "/mi2" or "/mobinfo2" on the chat prompt to open the MobInfo options
dialog. This dialog gives you full interactive control over EVERYTHING that
MobInfo can do. All options take immediate effect. Simply try them all out.
Decent defaults get set when you start MobInfo for the first time. Note that the
3 main categories "Tooltip", "Mob Health/Mana", and "Database Maintenance" have
separate dedicated options pages within the options dialog.

Note that everything in the options dialog has an associated help text that
explains to you what the option does. The help texts are shown automatically as
a tooltip.


*******************************************
*** How to Backup your MobInfo database ***
*******************************************
It is very IMPORTANT to make occasional (even better: regular) backups of your
MobInfo database. 
I have received several reports of users where due to whatever likely or
unlikely incident the original MobInfo database got lost or erased or erased or
currupted. It is unlikely and happens only very rarely, but when it happens your
only chance to recover is to have a backup of the MobInfo database.

The entire MobInfo database is contained within this onr file:
   World of Warcraft\WTF\Account\<your_account_name>\SavedVariables\MobInfo.lua

First of all please logout of WoW. This automagically saves all current AddOn
data to disk. Then make a copy of the database file (the one specified above) to
a save location. To restore the backed up data simply copy the backup file back
to the original location.

Side note: this is also the file that you must pass on if you want to give your
MobInfo database to someone else. Which of course means it is also the file you
receive when someone else gives you their MobInfo database.


**********************************************
*** IMPORT of an External MobInfo Database ***
**********************************************
MobInfo can import externally supplied MobInfo databases. This can be a database
from a friend of yours or a database that you have downloaded somewhere.
WARNING : the database that you import MUST be from someone who uses exactly the
same WoW localization as you do (ie. the same WoW client language). Importing a
MobInfo database from someone using a different WoW language will NOT work and
might corrupt your own database.

First of all before importing data you should make a backup of your own
database. This is explained above in the chapter "How to Backup your MobInfo 
database". It never hurts to be able to restore your original data in case you
are unhappy with the import result. 

Here are the detailed import instructions:

1) Close your WoW client

2) Backup your MobInfo database as explained above

3) Rename the database file that you want to import from "MobInfo.lua" to
   "MI2_Import.lua"

4) Copy the file "MI2_Import.lua" into this folder:
   \World of Warcraft\_<product>\Interface\AddOns\MobInfo\
   That is the folder where the AddOn has been installed, it MobInfo ships a
   default file with only a space in it, so if you replace it, it will gets
   loaded automatically by WoW.

5) Start WoW and login with one of your chars

6) Open the MobInfo options (enter "/mi2" at the chat prompt) and go to the
   "Database" options page. Near the bottom of the page you should now see
   whether the AddOn has found valid data to be imported. If you did everything
   correctly the "Import" button should be clickable.

7) Choose whether you want to import only unknown Mobs, otherwise all Mobs will
   get imported. If a Mob already exists in your database and you choose to
   import it the data of the new Mob will get added to the data of the existing
   Mob. Now click the Import button to star the database import operation. In
   your normal chat window you will see a summary of the import results.
   Please note that no characters specific data is copied or merged during the
   import.

8) Logout to cause WoW to save your now extended MobInfo database file. You
   should now replace the contents of the file "MI2_Import.lua" with something
   loadable (one space should suffice, the file cannot be empty). It is no
   longer needed and it will waste memory if contents is not replaced.

TIP  : use the "import only unknown Mobs" if you know that there is a large
       amount of overlap between your current database and the imported
       database. For instance if you import data from the same source again
       (because a newer version was released).


***-----------------------------------------------***
***-----------------------------------------------***
      F. A. Q. - Frequently Asked Questions
***-----------------------------------------------***
***-----------------------------------------------***


******************************************************************
** How do I change tooltip position or tooltip popup behaviour ?
******************************************************************
MobInfo only adds information to the tooltip, but it does not modify where or
how the tooltip appears. To change this there are a large number of real good
tooltip control AddOns available. I can't list them all here, but some of the
better and more popular ones are:
TipTac Reborn (https://www.curseforge.com/wow/addons/tiptac-reborn)

TipBuddy (http://ui.worldofwar.net/ui.php?id=607), 
TooltipRealmInof (https://www.curseforge.com/wow/addons/tooltiprealminfo)



***-----------------------------------------------***
***-----------------------------------------------***
             MobInfo-2 Version History
***-----------------------------------------------***
***-----------------------------------------------***

11.0.20
  * Make Import functionality work again
  * Reset MobInfoDB, which is no longer used once upgraded. It could cause
    "constant table overflow" error. Will rework the storage of information in a
    future update, but this should give some more breathing room.
  * Fixed issue when processing items within another item.
  * Fixed issue with fishing, wrong association was made.
  * Fixed issue with adding vendor prices.
  * Fixed issue with disenchants, for which mob (aka item) should be ignored.
  * Added safe guards around ITEM_LOCKED processing
  * Fixed issue with CheckInteractDistance, which is not always safe to use
    while in combat 
  * Removed debug print statements
  * Major internal rewrite of MobInfo2 to use the Mob Id instead of the Mob Name
  * Added specific location tracking for Mobs
  * Better support for localization
  * Database automatically upgraded

10.1.24
  * Fix item lookup for items with a / in the name (like "OOX-17/TN Distress
    Beacon")
  * Fix level nil issue
  * Add support for pet tooltips
  * Fix showing 0% health/mana
  * Fix sort number of non mobs on summary dialog
  * Enable Summary dialog functionality - hopefully all taint issues are fixed,
    if not please report
  * Add Show Class option
  * Disable Summary dialog functionality in retail for now.
  * Change ESCAPE key logic to no longer use UISpecialFrames, also removed
    UIPanelWindows setting
  * Updated to hopefully prevent taint messages
  * Change the way active Health/Mana is shown, add scaling
  * Add additional extra info lines to Tooltip
  * Add double click way point to Mob Search if TomTom is enabled (uses center
    point of bounds, and might be off if mobs are spread out)
  * Add English localization for added Summary dialog
  * Add new Summary dialog
  * Activated by /mi2 summary or by Right Clicking on the MobInfo2 icon
  * Shows the loots collected and the sources of the loots (including game
    objects) since login/reload
  * If Auctionator is available it will use auction price for items looted to
    calculate value of loots
  * Option to reset the Summary dialog
  * Option to change the font of the results lists
  * Filtering of the loot results, not filtering currently supported for sources
  * If Shift key is down and you hover of the result rwo, the ID will be added
    to the Name
  * plus more...
  * WoW does not provide API to look up names based on GameObject IDs. MobInfo
    will use the title of the GameTooltip if available when gathering/mining/
    opening Game Objects. In some cases the Game Tooltip is not available or it
    has unrelated information in it. The name of the Game Object might show up
    as an ID or an unrelated name. The name of the mob might show up as an
    internal id, when the mob was killed without ever having targeted or moused
    over it. 
  * Add minor changes to address Blizzard's changes to Wrath of the Lich King.
  * Add support for trade skill quality tiers. Cross reference is now done based
    on item id instead of item name.
  * Add indenting support for quest objectives
  * Using GetBuildInfo instead of GetExpansionLevel to determine WoW version
    active
  * Updated SetUnit callback to only handle GameTooltip ones in retail
  * Fix health issue when target turns from not attackable to attackable
  * Change tooltip handling to take advantage of changes in retail and fixed
    minor bugs in that area
  * Fix reload issue causing health processing issues
  * Use GetMoneyString to display values
  * Use item link instead of item id to get item info (value of item can be
    different based on level) where possible
  * Fixed issue with Blizzard removing LOOT_SLOT_X constants, using hard coded
    values to ensure older clients still work with the same code base
  * Also use emptyLoot count when calculating percentages
  * Some Expansion Level Constants were removed causing 'Search' to fail
    (Classic)
  * Updated to support DragonFlight

10.0.17
  * Added missing dependency
  * Added Rare and Rare Elite search options
  * Fixed Health/Mana display
  * No longer using offset configuration (but left config for now)
  * Make sure the 'Search' tab is the default one when clicking MobInfo2 button
    or using /MI2
  * One addon for all WoW versions
  * Fixed issue with duplication when using the GameTooltip only in classic
    versions
  * Increased extra info from 4 to 6 lines
  * Updated BCC and Classic to address the border issues (ported change from
    Retail)
  * Fixed issue with cloth counting in retail
  * Add Currency Loot and fix combine mob issue.

9.0.18
  * Revamped the looting algorithm to account for delayed events, which was
    causing loots to be missed in Retail.
  * As of version 9.0.12 MobInfo2 supports LibDBIcon and LibDataBroker. This
    means that Titan for example allows you to add MobInfo icon or SexyMap to
    recognize MobInfo2. Classic now support empty loot count again.
  * As of version 9.0.10 anchor location of the tooltip is now saved as part of
    configuration and not just by player. 
  * As of version 9.0.8 option is added to "Save all party kills", which is
    turned off by default. Also player's pet kills are now accounted for.
  * As of version 9.0.7 individual kill count is accounted for
  * As of version 9.0.2 individual loot is accounted for when looting multiple
    mobs
  * Updated WoW Classic version as well - check it out.

7.00
  * Make MobInfo2 work with WoW Legion. Will work on cleaning up the AddOn.
  
3.83
  * fixed the Delete Database-Buttons
    (hopefully I have found all errors now!) 

3.82
  * fixed Dropdown-menus now!
    Sorry to all, because I only checked the tickets and not checked the
    comments.
    Sorry again for my bad test before release a new version (I only looked for
    bug messages).
    Special thanks goes to Speedwaystar for his very good Comment!
  * changed the Itemvalue-Function, now the addon is using the price, we are 
    getting directly from WOW-Server. This should solve the issue, that we don't 
    have prices for the items new in WotLK (3.x) and Cata (4.x). MI2_ItemData
    is used as fallback for sure, but I plan to remove it in future versions.
    Thanks goes to next96
  * some minor fixes and improvements

3.81
  * fixed: Command line options (/mi2 /Mobinfo2 /mobinfo) was not working in
    v3.80
    => solved Ticket 25, thanks Speeddymon

3.80
  * fixed the 3.2 PTR bug from Version 3.73 / 3.74 on a bether way
  * fixed hopefully all bugs, so that the Addon is working for 4.0.1
  * Upgrade Loottable in Mobinfo2 (taken from the old Mobinfo3) 
  * Bether UnitClassification: rare (!), elite (+), rareelite (!+), worldboss
    (++)
  * Changed priority of itemvalue determination a little bit
  * For former users of Mobinfo3  can use the Mobinfo3 database:
    - Please rename the file MobInfo3.lua into Mobinfo2.lua in the WOW-Folder
      WTF\Account\%YOUR_ACCOUNT%\SavedVariables)  
    - or you can use the Import function

3.75
  * changed: version is now repository keyword in developer working copy
  * updated: changelog

3.74
  * fixed: Fixed change for 3.2 PTR to work on 3.3 and above as well :-/

3.73
  * fixed: added changes for 3.2 PTR based on GetBuildInfo()

3.72
  * fixed: scroll error in search frame

3.71
  * fixed: added an old module into the system to tie it all together while I
    attempt to track down the bug.

3.70
  * fixed: A host of errors caused by the newest patch which resulted in
    cascading errors. WoW now provides MobHealth info so I am slowly weaning the
    modules off of the calculated data. This could cause random errors but I
    have yet to see any.  I am doing it this way to get a working  mod out
    quicker and to avoid rewriting the entire thing.

3.61
  * fixed: kills for Mobs that give no XP were not being counted  
  * conversion support for "DropRate" data removed
  
3.60
  * updated to be compatible with WoW 2.40
  * fixed: Mob class not being shown correctly (thanks to Zergreth for heads up
    and the fix)
  * fixed: health values from Beast Lore will no longer get lost
  * fixed: show BeastLore extra info correctly in MobInfo tooltip
  * fixed: nil bug on line 304 when using CowTip			  

3.52
  * updated the MobInfo built-in item price table
  * show NPC profession in NPC tooltip
  * use unit interaction color (green, yellow, red) for MobInfo tooltip frame	  

3.51
  * fixed a nil bug when hovering over items in item search result
  * fixed : search result sort by item count did not sort correctly
  * fixed a bug causing NPCs to get added to the MobInfo database
  * improved search speed when searching for items
  * do not show class for NPCs
	  
3.50
  * support 4 new skinning loot items
  * show the MobInfo tooltip also for NPCs
  * new search page option: max times looted
  * MobInfo built-in search page now searches in the background without blocking	 		  
  * attempted to fix the bug where the looting rights line for corpses was not
    shown in the MobInfo tooltip
  * fixed nil bug when opening soft-shelled clam
	  

Known Problems / Limitations:
  * several localisations do not work and must be updated: TW, PL
  * localisations that urgently require updates: FR, ES