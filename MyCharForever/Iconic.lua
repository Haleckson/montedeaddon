local addonName, MCF = ...
-- Iconic moments: well-known places, bosses, quests and items of Azeroth that most players
-- remember (Hogger, the Green Hills pages, Booty Bay ...). Everything is event based, no combat log.
--
-- Each moment is recognised by NAME (kills, zones, items), because the game gives us names but no
-- stable ids for most of this. Names are compared lower-case with a plain substring search, and
-- every moment lists the English and German spellings. A moment that never triggers because a
-- client spells a name differently is a one-line fix in the table below (`/mcf iconic` shows what
-- the addon has actually seen recently, to make that easy).
--
-- Saved per character in MyCharForeverDB.iconic.moments[id] = {count, first, last, set}
--   first = {time, level, zone, subZone}  -- the first time it happened
--   set   = {[key]=true}                  -- distinct things collected (for kind "collect")

local VISIT_GAP = 600       -- seconds away before coming back counts as a new visit
local RIDE_WINDOW = 480     -- seconds between two docks for a boat ride
local RECENT_MAX = 12

-- kind: kill | death | visit | talk | quest | collect | ride
-- names: lower-case keywords (English and German); zone: optional, the moment only counts there
-- deLore/enLore: short background paragraph (why the moment is iconic), shown in the viewer; the text comes from general Warcraft lore
-- capital: true on the six capitals; every real entry is counted in db.tracking.capitals (Tracking.lua), independent of the iconic switch
-- total: for "collect", how many distinct things exist (shown as x / total)
-- Groups of the list (id, German, English); the addon UI and the viewer table both read this one definition.
MCF.IconicGroups = {
    {"kills", "Legendäre Begegnungen", "Legendary Encounters"},
    {"places", "Orte, die man gesehen haben muss", "Places You Have to See"},
    {"items", "Sammelstücke und Queststücke", "Collectibles and Quests"},
    {"travel", "Unterwegs", "On the Road"},
}

MCF.IconicMoments = {
    -- Kills
    {id="hogger", group="kills", kind="kill", names={"hogger",
        deStory="Hogger liegt im Staub! Unzählige Neulinge vor mir sind an ihm gescheitert, heute nicht.", enStory="Hogger is down! Countless newcomers before me fell to him, not today."},
        de="Hogger erlegt", en="Hogger Slain", deDesc="Besiege den berüchtigten Gnoll-Anführer von Elwynn.", enDesc="Defeat the infamous gnoll leader of Elwynn.",
        deLore="Hogger ist der Anführer der Gnolle im Wald von Elwynn und ein Handlanger der Defias-Bruderschaft. Für unzählige Neulinge der Allianz war er der erste Elite-Gegner, an dem sie scheiterten, und genau das machte ihn zu einer der bekanntesten Nebenfiguren des ganzen Spiels.", enLore="Hogger is the leader of the gnolls in Elwynn Forest and an agent of the Defias Brotherhood. For countless Alliance newcomers he was the first elite enemy they failed against, and that made him one of the best-known minor characters of the whole game."},
    {id="hogger_death", group="kills", kind="death", names={"hogger",
        deStory="Hogger hat mich umgehauen. Ich nenne es eine strategische Pause und wir sprechen nicht mehr darüber.", enStory="Hogger flattened me. I call it a strategic pause and we never speak of it again."},
        de="Von Hogger vermöbelt", en="Beaten by Hogger", deDesc="Lass dich von Hogger töten. Es bleibt unter uns.", enDesc="Get killed by Hogger. It stays between us.",
        deLore="Hogger ist als Elite-Gegner mitten in ein Gebiet für Stufe-1-Helden gesetzt: Wer ihm zu früh gegenübertritt, hat kaum eine Chance. Seine Niederlagen gehören für viele Allianz-Spieler zum Einstand in Azeroth, fast wie ein Initiationsritus.", enLore="Hogger is an elite enemy placed in the middle of an area for level 1 heroes: whoever meets him too early has hardly a chance. Losing to him is part of the arrival in Azeroth for many Alliance players, almost a rite of passage."},
    {id="vancleef", group="kills", kind="kill", names={"vancleef",
        deStory="Edwin VanCleef ist Geschichte. Die Todesminen wirken plötzlich viel gemütlicher.", enStory="Edwin VanCleef is history. The Deadmines suddenly feel a lot cozier."},
        de="Edwin VanCleef", en="Edwin VanCleef", deDesc="Besiege den Anführer der Defias in den Todesminen.", enDesc="Defeat the Defias leader in the Deadmines.",
        deLore="Edwin VanCleef war einer der Steinmetze, die Sturmwind nach dem Ersten Krieg wieder aufbauten. Als der Adel die Handwerker um ihren Lohn prellte, gründete er die Defias-Bruderschaft und machte die Todesminen zu seinem Versteck. Seine Bande überfiel Sturmwinds Land, bis Abenteurer ihm dort das Handwerk legten.", enLore="Edwin VanCleef was one of the stonemasons who rebuilt Stormwind after the First War. When the nobility cheated the craftsmen of their pay, he founded the Defias Brotherhood and made the Deadmines his hideout. His gang raided the lands of Stormwind until adventurers put an end to it there."},
    {id="princess", group="kills", kind="kill", names={"princess", "prinzessin",
        deStory="Ich habe die Prinzessin besiegt. Ein Eber mit Titel, ein Gegner mit Würde.", enStory="I defeated the Princess. A boar with a title, a foe with dignity."},
        de="Die Prinzessin", en="The Princess", deDesc="Besiege die Prinzessin, das Eber-Heiligtum auf dem Steinfeldhof im Wald von Elwynn.", enDesc="Defeat the Princess, the beloved boar of Stonefield Farm in Elwynn Forest.",
        deLore="Die Prinzessin ist ein seltener Eber auf dem Steinfeldhof im Wald von Elwynn. Ein Wildschwein mit königlichem Titel ist typisch für den Humor der Entwickler und hat sie zum Liebling der Spielergemeinde gemacht.", enLore="The Princess is a rare boar at Stonefield Farm in Elwynn Forest. A wild pig with a royal title is typical of the developers' humour and made her a favourite of the player community."},
    {id="stitches", group="kills", kind="kill", names={"stitches", "flickwerk",
        deStory="Stitches ist gefallen. Düsterwald schläft heute Nacht ein bisschen ruhiger.", enStory="Stitches has fallen. Duskwood sleeps a little easier tonight."},
        de="Stitches, der Fleischberg", en="Stitches the Abomination", deDesc="Besiege Stitches, den Fleischberg aus Düsterwald.", enDesc="Defeat Stitches, the abomination of Duskwood.",
        deLore="Stitches ist ein Fleischberg, zusammengenäht aus Leichenteilen und mit dunkler Nekromantie zum Leben erweckt. Er wandert durch den Düsterwald und hinterlässt Angst und Verwüstung; ihn zu stoppen gilt als Mutprobe für Helden der mittleren Stufen.", enLore="Stitches is a flesh abomination, sewn together from body parts and brought to life by dark necromancy. He lumbers through Duskwood leaving fear and ruin behind; stopping him is a test of courage for heroes of the middle levels."},
    {id="morladim", group="kills", kind="kill", names={"mor'ladim",
        deStory="Mor'Ladim ist zur Ruhe gebettet, endgültig. Hoffentlich.", enStory="Mor'Ladim is laid to rest, for good. Hopefully."},
        de="Mor'Ladim", en="Mor'Ladim", deDesc="Besiege den Untoten Mor'Ladim in Düsterwald.", enDesc="Defeat the undead Mor'Ladim in Duskwood.",
        deLore="Mor'Ladim ist ein mächtiger Untoter und einer der gefürchteten Elite-Gegner im finsteren Düsterwald. Der Wald ist seit jeher verflucht, und wer Mor'Ladim bezwingt, beweist, dass er den Schrecken dieser Gegend gewachsen ist.", enLore="Mor'Ladim is a powerful undead and one of the feared elite enemies in the gloomy Duskwood. The forest has long been cursed, and whoever defeats Mor'Ladim proves to be a match for the terrors of this region."},
    {id="gamon", group="kills", kind="kill", names={"gamon",
        deStory="Gamon ist erlegt. Ja, genau der, vor den Toren Orgrimmars und vor aller Augen.", enStory="Gamon is slain. Yes, that one, right outside Orgrimmar in plain sight."},
        de="Gamon: Der Unverwundbare", en="Gamon the Invincible", deDesc="Erlege Gamon vor Orgrimmar. Ja, er ist gemeint.", enDesc="Slay Gamon outside Orgrimmar. Yes, that one.",
        deLore="Gamon steht vor den Toren Orgrimmars und ist ein kleines Stück Spiel-Folklore: ein Orc, der dort scheinbar nur im Weg steht und dem viele Spieler zuerst mit Respekt aus dem Weg gingen. Ihn zu besiegen ist eher ein Insider-Spaß als eine echte Heldentat.", enLore="Gamon stands outside the gates of Orgrimmar and is a little piece of game folklore: an orc who seems to be merely standing around and whom many players first gave a respectful berth. Defeating him is more of an in-joke than a true heroic deed."},
    {id="bangalash", group="kills", kind="kill", names={"bangalash",
        deStory="König Bangalash, der weiße Tiger, liegt zu meinen Füßen. Was für ein Fell!", enStory="King Bangalash, the white tiger, lies at my feet. What a pelt!"},
        de="König Bangalash", en="King Bangalash", deDesc="Besiege den weißen Tiger im Schlingendorntal.", enDesc="Defeat the white tiger of Stranglethorn.",
        deLore="König Bangalash ist ein seltener weißer Tiger im Schlingendorntal. Seine Jagd gilt unter Spielern als besondere Trophäe, denn die Raubkatzen des Dschungels sind schon gefährlich genug, und er ist der König unter ihnen.", enLore="King Bangalash is a rare white tiger in Stranglethorn Vale. Hunting him is regarded among players as a special trophy, because the big cats of the jungle are dangerous enough, and he is the king among them."},
    {id="devilsaur", group="kills", kind="kill", names={"devilsaur", "teufelssaurier",
        deStory="Ein Teufelssaurier weniger in Un'Goro. Mein Herz hämmert immer noch.", enStory="One devilsaur fewer in Un'Goro. My heart is still pounding."},
        de="Dinojäger", en="Dino Hunter", deDesc="Erlege einen Teufelssaurier in Un'Goro.", enDesc="Slay a devilsaur in Un'Goro Crater.",
        deLore="Teufelssaurier sind die Spitzenräuber des Un'Goro-Kraters, eines Tals, das von der Außenwelt fast unberührt blieb und in dem noch Urzeitwesen leben. Ihre Haut gilt als begehrter Rohstoff für Lederer, und wer einen erlegt, hat sich mit dem gefährlichsten Jäger des Kraters angelegt.", enLore="Devilsaurs are the apex predators of Un'Goro Crater, a valley that stayed almost untouched by the outside world and still harbours prehistoric creatures. Their hide is a prized material for leatherworkers, and whoever slays one has taken on the most dangerous hunter of the crater."},
    -- Places
    {id="stormwind", group="places", kind="visit", capital=true, names={"stormwind city", "sturmwind",
        deStory="Mein erster Besuch in Sturmwind. So viele Türme, so viele Leute, so viele Wege zum Verlaufen.", enStory="My first visit to Stormwind. So many towers, so many people, so many ways to get lost."},
        de="Sturmwind betreten", en="Entered Stormwind", deDesc="Besuche die Hauptstadt der Allianz.", enDesc="Visit the Alliance capital.",
        deLore="Sturmwind ist die Hauptstadt der Menschen und das Herz der Allianz. Die Stadt wurde im Ersten Krieg von der Horde niedergebrannt und danach mühsam wieder aufgebaut, mit Steinmetzen, deren Schicksal später zur Defias-Bruderschaft führte.", enLore="Stormwind is the capital of the humans and the heart of the Alliance. The city was burned down by the Horde in the First War and rebuilt with great effort, using stonemasons whose fate later led to the Defias Brotherhood."},
    {id="ironforge", group="places", kind="visit", capital=true, names={"ironforge", "eisenschmiede",
        deStory="Mein erster Besuch in Eisenschmiede. Es ist warm, es ist laut, und überall riecht es nach Bier.", enStory="My first visit to Ironforge. It is warm, it is loud, and everything smells of beer."},
        de="Eisenschmiede betreten", en="Entered Ironforge", deDesc="Besuche die Zwergenstadt im Berg.", enDesc="Visit the dwarven city inside the mountain.",
        deLore="Eisenschmiede ist die Hauptstadt der Zwerge, tief in den Berg von Dun Morogh gehauen. Hier regiert das Haus Bronzebart; in den Hallen glüht die Große Schmiede, an der das Volk seit Jahrhunderten Waffen und Rüstungen fertigt.", enLore="Ironforge is the dwarven capital, carved deep into the mountain of Dun Morogh. House Bronzebeard rules here; in its halls glows the Great Forge, where the people have made weapons and armour for centuries."},
    {id="darnassus", group="places", kind="visit", capital=true, names={"darnassus",
        deStory="Mein erster Besuch in Darnassus. Zwischen den Baumkronen fühlt man sich fast schwerelos.", enStory="My first visit to Darnassus. Up in the treetops you feel almost weightless."},
        de="Darnassus betreten", en="Entered Darnassus", deDesc="Besuche die Stadt in den Baumkronen.", enDesc="Visit the city in the treetops.",
        deLore="Darnassus ist die Hauptstadt der Nachtelfen, hoch oben in den Ästen des Weltenbaums Teldrassil. Eine Stadt aus Wurzeln, Mondlicht und Stille, die von den Tempeln der Elune geprägt ist.", enLore="Darnassus is the capital of the night elves, high up in the branches of the World Tree Teldrassil. A city of roots, moonlight and calm, shaped by the temples of Elune."},
    {id="orgrimmar", group="places", kind="visit", capital=true, names={"orgrimmar",
        deStory="Mein erster Besuch in Orgrimmar. Staub, Trommeln und ein Hauch von Abenteuer.", enStory="My first visit to Orgrimmar. Dust, drums and a hint of adventure."},
        de="Orgrimmar betreten", en="Entered Orgrimmar", deDesc="Besuche die Hauptstadt der Horde.", enDesc="Visit the Horde capital.",
        deLore="Orgrimmar ist die Hauptstadt der Horde in Durotar, benannt nach dem gefallenen Kriegshäuptling Orgrim Doomhammer. Thrall gründete die Stadt, als er sein Volk in eine neue Heimat führte, fern von den Lagern, in die man die Orcs einst gesperrt hatte.", enLore="Orgrimmar is the capital of the Horde in Durotar, named after the fallen warchief Orgrim Doomhammer. Thrall founded the city when he led his people to a new home, far from the camps in which the orcs had once been confined."},
    {id="thunderbluff", group="places", kind="visit", capital=true, names={"thunder bluff", "donnerfels",
        deStory="Mein erster Besuch in Donnerfels. Die Aussicht von den Felsen ist unbezahlbar.", enStory="My first visit to Thunder Bluff. The view from the mesas is priceless."},
        de="Donnerfels betreten", en="Entered Thunder Bluff", deDesc="Besuche die Stadt auf den Felsen.", enDesc="Visit the city on the mesas.",
        deLore="Donnerfels ist die Hauptstadt der Tauren, auf hohen Felsplateaus über der Weite von Mulgore gebaut. Hier ist das Volk um Hochhäuptling Cairne Bloodhoof zu Hause, das im Einklang mit der Erdmutter lebt.", enLore="Thunder Bluff is the capital of the tauren, built on high mesas above the plains of Mulgore. It is home to the people of High Chieftain Cairne Bloodhoof, who live in harmony with the Earthmother."},
    {id="undercity", group="places", kind="visit", capital=true, names={"undercity", "unterstadt",
        deStory="Mein erster Besuch in der Unterstadt. Es riecht nach Seuche und Moder, und trotzdem fühlt es sich nach Heimat an.", enStory="My first visit to the Undercity. It smells of plague and mould, and still it feels like home."},
        de="Unterstadt betreten", en="Entered the Undercity", deDesc="Besuche die Stadt unter den Ruinen.", enDesc="Visit the city beneath the ruins.",
        deLore="Die Unterstadt liegt in den Kellern und Kanälen der zerstörten Hauptstadt Lordaerons. Hier hat sich Sylvanas Windläufer mit den Verlassenen, den befreiten Untoten, eine eigene Heimat geschaffen, unter den Ruinen des einstigen Königreichs.", enLore="The Undercity lies in the cellars and sewers of the ruined capital of Lordaeron. Here Sylvanas Windrunner and the Forsaken, the freed undead, built a home of their own beneath the ruins of the former kingdom."},
    {id="deeprun", group="places", kind="visit", names={"deeprun tram", "tiefenbahn",
        deStory="Ich habe die Tiefenbahn genommen. Ein Tunnel, ein Wagen und ganz viel Hoffnung, dass sie hält.", enStory="I took the Deeprun Tram. One tunnel, one carriage and a lot of hope that it holds."},
        de="Tiefenbahn", en="Deeprun Tram", deDesc="Betritt die Tiefenbahn zwischen Sturmwind und Eisenschmiede.", enDesc="Enter the Deeprun Tram between Stormwind and Ironforge.",
        deLore="Die Tiefenbahn ist eine unterirdische Bahnstrecke, die Sturmwind und Eisenschmiede verbindet. Gebaut wurde sie als gemeinsames Werk der Verbündeten, ein Wunder der Ingenieurskunst, durch das man den Weg unter dem Gebirge in wenigen Minuten zurücklegt.", enLore="The Deeprun Tram is an underground railway connecting Stormwind and Ironforge. It was built as a joint work of the allies, a marvel of engineering that lets you cross beneath the mountains in a few minutes."},
    {id="gurubashi", group="places", kind="visit", names={"gurubashi",
        deStory="Ich stehe in der Gurubashi-Arena. Hier wurden schon Legenden geboren und viele Rucksäcke geplündert.", enStory="I am standing in the Gurubashi Arena. Legends were born here, and many backpacks were looted."},
        de="Gurubashi-Arena", en="Gurubashi Arena", deDesc="Betritt die berühmte Arena im Schlingendorntal.", enDesc="Enter the famous arena in Stranglethorn Vale.",
        deLore="Die Gurubashi-Arena im Schlingendorntal ist ein Überbleibsel des alten Trollreichs der Gurubashi. Heute messen sich Abenteurer hier im Zweikampf, und der Ort ist unter Spielern berühmt für Duelle, Herausforderungen und manche Geschichte vom Sieg in letzter Sekunde.", enLore="The Gurubashi Arena in Stranglethorn Vale is a relic of the ancient troll empire of the Gurubashi. Today adventurers test themselves in single combat here, and the place is famous among players for duels, challenges and many a tale of a last-second victory."},
    {id="bootybay", group="places", kind="visit", names={"booty bay", "beutebucht",
        deStory="Mein erster Besuch in Beutebucht. Piraten, Goblins und Gold, hier fühle ich mich gleich wohl.", enStory="My first visit to Booty Bay. Pirates, goblins and gold, I feel right at home."},
        de="Beutebucht", en="Booty Bay", deDesc="Besuche die Goblinstadt an der Küste.", enDesc="Visit the goblin port town.",
        deLore="Beutebucht ist die Hafenstadt der Goblins im Süden des Schlingendorntals, eine neutrale Stadt unter der Führung des Handelsfürsten-Kartells. Hier legen Schiffe aus aller Welt an, und jeder, ob Allianz oder Horde, ist willkommen, solange seine Münzen stimmen.", enLore="Booty Bay is the goblin port town in the south of Stranglethorn Vale, a neutral city run by the merchant cartel. Ships from all over the world dock here, and everyone, Alliance or Horde, is welcome as long as their coins are good."},
    {id="darkportal", group="places", kind="visit", names={"dark portal", "dunkle portal",
        deStory="Ich stehe vor dem Dunklen Portal. Dahinter liegt eine andere Welt, und sie sieht nicht freundlich aus.", enStory="I am standing before the Dark Portal. A different world lies beyond it, and it does not look friendly."},
        de="Das Dunkle Portal", en="The Dark Portal", deDesc="Stehe vor dem Tor zwischen den Welten.", enDesc="Stand before the gate between worlds.",
        deLore="Das Dunkle Portal in den Verwüsteten Landen ist das Tor zwischen Azeroth und Draenor. Durch dieses Tor strömte im Ersten Krieg die Horde in unsere Welt, nachdem der Wächter Medivh es geöffnet hatte, und bis heute ist es der Ort, an dem die Geschichte des Konflikts begann.", enLore="The Dark Portal in the Blasted Lands is the gate between Azeroth and Draenor. Through this gate the Horde poured into our world in the First War after the Guardian Medivh opened it, and to this day it is the place where the story of the conflict began."},
    {id="karazhan", group="places", kind="visit", names={"karazhan",
        deStory="Ich stehe vor den Toren Karazhans. Der Turm wirkt, als wüsste er mehr über mich als ich selbst.", enStory="I am standing at the gates of Karazhan. The tower seems to know more about me than I do."},
        de="Vor den Toren Karazhans", en="At Karazhan's Gates", deDesc="Besuche den Turm des Magus.", enDesc="Visit the Magus' tower.",
        deLore="Karazhan ist der Turm des Wächters Medivh im Gebirgspass der Totenwinde. Das düstere Gemäuer wurde einst von seinem Vater erbaut und gilt als Ort magischer Geheimnisse, von denen die Gerüchte seit Langem erzählen; wer davorsteht, spürt, dass hier etwas wartet.", enLore="Karazhan is the tower of the Guardian Medivh in Deadwind Pass. The gloomy walls were once built by his father and are said to hold magical secrets that rumours have told of for a long time; whoever stands before it feels that something is waiting there."},
    {id="onyxia", group="places", kind="visit", names={"onyxia",
        deStory="Ich habe Onyxias Hort betreten. Hier riecht es nach Drache und nach schlechten Entscheidungen.", enStory="I have entered Onyxia's Lair. It smells of dragon and of bad decisions."},
        de="Onyxias Hort", en="Onyxia's Lair", deDesc="Wage dich in die Höhle des schwarzen Drachen.", enDesc="Venture into the black dragon's lair.",
        deLore="Onyxia ist die Tochter des Schwarzen Drachen Todesschwinge. Als Katrana Prestor verkleidet, spann sie am Hof von Sturmwind ihre Intrigen, bevor ihre Tarnung aufflog und sie sich in ihr Versteck in den Düstermarschen zurückzog, wo sie auf Eindringlinge wartet.", enLore="Onyxia is the daughter of the black dragon Deathwing. Disguised as Katrana Prestor, she wove her intrigues at the court of Stormwind before her cover was blown and she withdrew to her lair in Dustwallow Marsh, where she waits for intruders."},
    {id="kodograve", group="places", kind="visit", names={"kodo graveyard", "kodofriedhof",
        deStory="Der Kodofriedhof ist ein stiller, trauriger Ort. Der Wind trägt das Echo alter Zeiten.", enStory="The Kodo Graveyard is a quiet, sad place. The wind carries the echo of old times."},
        de="Kodofriedhof", en="Kodo Graveyard", deDesc="Besuche den traurigen Ort in Desolace.", enDesc="Visit the sad place in Desolace.",
        deLore="Auf dem Kodo-Friedhof in Desolace liegen die gewaltigen Knochen der Kodos, die sich hierher zum Sterben zurückziehen. Ein stiller, düsterer Ort, der vielen Spielern nachgeht und der in der Tauren-Überlieferung seine eigene Bedeutung hat.", enLore="On the Kodo Graveyard in Desolace lie the vast bones of the kodos that retreat here to die. A quiet, gloomy place that stays with many players and has its own meaning in tauren tradition."},
    -- Talking to the leaders of the capitals (first conversation: gossip or quest window opened with them)
    {id="thrall", group="places", kind="talk", names={"thrall"},
        de="Handschlag mit dem Kriegshäuptling", en="A Word with the Warchief", deDesc="Sprich mit Thrall in Orgrimmar.", enDesc="Talk to Thrall in Orgrimmar.",
        deLore="Thrall wuchs als Sklave und Gladiator unter dem Menschen Aedelas Blackmoore auf. Er befreite die Orcs aus den Internierungslagern, wurde Schamane und führte sein Volk als Kriegshäuptling in die neue Heimat Durotar, wo er Orgrimmar gründete.", enLore="Thrall grew up as a slave and gladiator under the human Aedelas Blackmoore. He freed the orcs from the internment camps, became a shaman and led his people as Warchief to a new home in Durotar, where he founded Orgrimmar.",
        deStory="Ich habe mit Thrall gesprochen. Er hörte zu, als wäre ich die wichtigste Person in ganz Orgrimmar.", enStory="I spoke with Thrall. He listened as if I were the most important person in all of Orgrimmar."},
    {id="sylvanas", group="places", kind="talk", names={"sylvanas"},
        de="Smalltalk mit der Bansheekönigin", en="Small Talk with the Banshee Queen", deDesc="Sprich mit Sylvanas in der Unterstadt.", enDesc="Talk to Sylvanas in the Undercity.",
        deLore="Sylvanas Windläufer war einst Waldläufergeneralin von Silbermond und wurde von Arthas getötet und als Banshee erweckt. Nachdem sie sich vom Joch des Lichkönigs befreit hatte, führte sie die Verlassenen und machte die Unterstadt zu ihrer Festung.", enLore="Sylvanas Windrunner was once Ranger-General of Silvermoon and was killed by Arthas and raised as a banshee. After breaking free from the yoke of the Lich King she led the Forsaken and made the Undercity her fortress.",
        deStory="Ich habe mit Sylvanas gesprochen. Ihr Lächeln ist freundlich, ihre Augen sind es nicht.", enStory="I spoke with Sylvanas. Her smile is friendly, her eyes are not."},
    {id="cairne", group="places", kind="talk", names={"cairne"},
        de="Bei Cairne auf der Matte", en="Standing on Cairne's Mat", deDesc="Sprich mit Cairne Bluthuf in Donnerfels.", enDesc="Talk to Cairne Bloodhoof in Thunder Bluff.",
        deLore="Cairne Bloodhoof, Sohn des Grull Bloodhoof, ist der Hochhäuptling der Tauren und Gründer von Donnerfels. Er ist für Weisheit und Gelassenheit bekannt und gilt als treuer Freund Thralls, mit dem er die Horde zu einem Bündnis über die Völker hinweg verband.", enLore="Cairne Bloodhoof, son of Grull Bloodhoof, is the High Chieftain of the tauren and founder of Thunder Bluff. He is known for wisdom and calm and is regarded as a loyal friend of Thrall, with whom he bound the Horde into an alliance of many peoples.",
        deStory="Ich habe Cairne Bluthuf getroffen. Ein Handschlag von ihm und die Erde bebt.", enStory="I met Cairne Bloodhoof. One handshake from him and the ground shakes."},
    {id="bolvar", group="places", kind="talk", names={"bolvar", "varian", "wrynn"},
        de="Vor dem Hochlord", en="Before the Highlord", deDesc="Sprich mit dem Anführer von Sturmwind.", enDesc="Talk to the leader of Stormwind.",
        deLore="Hochlord Bolvar Fordragon führt die Staatsgeschäfte von Sturmwind, während der junge Prinz Anduin zu klein und König Varian verschwunden ist. Er gilt als pflichtbewusst, unbestechlich und tapfer, der Mann, der das Reich zusammenhält.", enLore="Highlord Bolvar Fordragon runs the affairs of Stormwind while the young Prince Anduin is too small and King Varian has vanished. He is regarded as dutiful, incorruptible and brave, the man who holds the realm together.",
        deStory="Ich stand vor dem Anführer Sturmwinds und habe mein Anliegen vorgetragen. Er hat tatsächlich zugehört.", enStory="I stood before the leader of Stormwind and made my case. He actually listened."},
    {id="magni", group="places", kind="talk", names={"magni"},
        de="Bartpflege bei Magni", en="Beard Care with Magni", deDesc="Sprich mit König Magni Bronzebart in Eisenschmiede.", enDesc="Talk to King Magni Bronzebeard in Ironforge.",
        deLore="Magni Bronzebart ist der König von Eisenschmiede und der Bruder des berühmten Muradin. Er herrscht über die Zwerge der Bronzebart-Linie, und auch wenn sein Bart legendär ist, ist es sein Eifer für das Wohl seines Volkes, der ihm den Respekt der Allianz eingebracht hat.", enLore="Magni Bronzebeard is the King of Ironforge and brother of the famous Muradin. He rules the dwarves of the Bronzebeard line, and though his beard is legendary, it is his zeal for the welfare of his people that earned him the respect of the Alliance.",
        deStory="Ich habe mit König Magni gesprochen. Sein Bart ist beeindruckender als jede Krone.", enStory="I spoke with King Magni. His beard is more impressive than any crown."},
    {id="tyrande", group="places", kind="talk", names={"tyrande"},
        de="Mondlicht-Audienz", en="Moonlit Audience", deDesc="Sprich mit Tyrande Wisperwind in Darnassus.", enDesc="Talk to Tyrande Whisperwind in Darnassus.",
        deLore="Tyrande Wisperwind ist die Hohepriesterin der Elune und seit Jahrtausenden Anführerin der Nachtelfen. Ihr Rat und ihr Glaube an die Mondgöttin haben ihr Volk durch dunkle Zeiten getragen, und im Tempel von Darnassus kann man sie persönlich sprechen.", enLore="Tyrande Whisperwind is the High Priestess of Elune and has led the night elves for millennia. Her counsel and her faith in the moon goddess carried her people through dark times, and in the temple of Darnassus you can speak with her in person.",
        deStory="Ich habe mit Tyrande Wisperwind gesprochen. Neben ihr fühlt sich selbst der Mondschein gewöhnlich an.", enStory="I spoke with Tyrande Whisperwind. Next to her even moonlight feels ordinary."},
    -- Quests
    {id="green_chapter", group="items", kind="quest", names={"chapter i", "kapitel i"}, pattern="^chapter [ivx]+$", patternDe="^kapitel [ivx]+$",
        de="Die Grünen Hügel: Kapitel", en="Green Hills: Chapters", deDesc="Gib ein Kapitel der Grünen Hügel von Schlingendorn ab.", enDesc="Turn in a chapter of the Green Hills of Stranglethorn.",
        deLore="Die Grünen Hügel von Schlingendorn sind eine ganze Kette von Aufträgen, in denen man die verstreuten Seiten eines Buches zusammensucht. Das Buch ist eine liebevolle Parodie auf Ernest Hemingways Jagdbericht, und sein Autor, der Großwildjäger Hemet Nesingwary, ein Augenzwinkern darauf.", enLore="The Green Hills of Stranglethorn is a whole chain of quests in which you gather the scattered pages of a book. The book is a loving parody of Ernest Hemingway's hunting account, and its author, the big-game hunter Hemet Nesingwary, is a wink at it.",
        deStory="Ein Kapitel der Grünen Hügel abgegeben. Die Jagd nach den Seiten hat sich gelohnt.", enStory="Handed in a chapter of the Green Hills. The hunt for the pages was worth it."},
    -- Items
    {id="green_pages", group="items", kind="collect", total=28,
        de="Seiten der Grünen Hügel", en="Green Hills Pages", deDesc="Sammle die Seiten der Grünen Hügel von Schlingendorn (28 insgesamt).", enDesc="Collect the pages of the Green Hills of Stranglethorn (28 in total).",
        deLore="Die 28 Seiten der Grünen Hügel liegen quer durch das Schlingendorntal verstreut, oft in gefährlichen Ecken. Wer sie alle gefunden hat, durfte viele Stunden im Dschungel verbringen, und für viele ist das Sammeln eine der liebsten Erinnerungen an die Frühzeit des Spiels.", enLore="The 28 pages of the Green Hills are scattered across Stranglethorn Vale, often in dangerous corners. Whoever found them all spent many hours in the jungle, and for many players the collecting is one of the fondest memories of the early game.",
        deStory="Meine erste Seite der Grünen Hügel! Nur noch 27 weitere.", enStory="My first page of the Green Hills! Only 27 more to go."},
    -- Travel
    {id="boat_ride", group="travel", kind="ride",
        de="Seebär", en="Sea Legs", deDesc="Fahre mit einem Schiff zwischen zwei Häfen.", enDesc="Ride a boat between two harbors.",
        deLore="Schiffe und Zeppeline verbinden die Küsten Azeroths. Das Warten am Pier, der Blick aufs Wasser und die Ruhe zwischen zwei Häfen gehören zum Reisegefühl der alten Welt, in der man noch Zeit hatte, die Landschaft zu genießen.", enLore="Ships and zeppelins connect the shores of Azeroth. Waiting at the pier, the view over the water and the calm between two harbours are part of the travel feeling of the old world, in which you still had time to enjoy the scenery.",
        deStory="Meine erste Seereise. Der Magen sagt nein, das Abenteuer sagt ja.", enStory="My first sea voyage. The stomach says no, the adventure says yes."},
}

-- Docks: canonical name -> keywords. A ride is a trip between two docks of a real route.
local DOCKS = {
    menethil = {"menethil"}, auberdine = {"auberdine"}, theramore = {"theramore"},
    rutheran = {"rut'theran", "rutheran"}, bootybay = {"booty bay", "beutebucht"}, ratchet = {"ratchet", "ratschet"},
}
local DOCK_NAMES = {menethil = "Menethil", auberdine = "Auberdine", theramore = "Theramore", rutheran = "Rut'theran", bootybay = "Booty Bay", ratchet = "Ratchet"}
local ROUTES = {
    ["menethil|auberdine"] = true, ["menethil|theramore"] = true,
    ["rutheran|auberdine"] = true, ["bootybay|ratchet"] = true,
}

local recent = {kills = {}, places = {}, items = {}, npcs = {}}

---------------------------------------------------------------------------
-- Storage
---------------------------------------------------------------------------
local function Store()
    local db = MyCharForeverDB
    if type(db) ~= "table" then return nil end
    db.iconic = db.iconic or {}
    db.iconic.moments = db.iconic.moments or {}
    return db.iconic.moments
end

local function Entry(id)
    local m = Store()
    if not m then return nil end
    m[id] = m[id] or {count = 0}
    return m[id]
end

local byId = {}
for _, d in ipairs(MCF.IconicMoments) do byId[d.id] = d end

-- Master switch (setting iconicEnabled, default on), same idea as "achievementsEnabled": off = nothing is detected,
-- announced, photographed, journaled or shown. Already saved moments stay untouched.
function MCF:IconicEnabled()
    local st = MyCharForeverDB and MyCharForeverDB.settings
    return not (st and st.iconicEnabled == false)
end

-- detail: what triggered it (killer/victim name, zone, NPC, quest or item), shown in the popup
-- Test unlocks (/mcf testunlock): the entry, its first-time record and its timeline event carry test=true so they can be told apart
-- from real finds and removed again. A test unlock only shows the popup, no chronicle screenshot and no journal entry.
local forceTest, quietTest = false, false
local function Hit(id, key, detail)
    if not MCF:IconicEnabled() then return end
    local e = Entry(id)
    if not e then return end
    if key then
        e.set = e.set or {}
        if e.set[key] then return end
        e.set[key] = true
    end
    e.count = (e.count or 0) + 1
    e.last = time()
    if not e.first then
        e.first = {time = time(), level = UnitLevel("player"), zone = GetZoneText(), subZone = GetSubZoneText(), test = forceTest or nil}
        if MCF.AddEvent then pcall(MCF.AddEvent, MCF, "ICONIC", {id = id, test = forceTest or nil}) end
        if forceTest then
            local def = byId[id]
            if def and MCF.ShowMomentToast and not quietTest then
                local german = MCF.GetLanguage and MCF:GetLanguage() == "deDE"
                pcall(MCF.ShowMomentToast, MCF, german and def.de or def.en, MCF:IconicTriggerText(def.kind, detail))
            end
        elseif MCF.OnIconicFirst then pcall(MCF.OnIconicFirst, MCF, id, detail) end
    end
    if MCF.RefreshUI then MCF:RefreshUI() end
end

-- First time a moment happens: optional chronicle screenshot + journal entry (both on by default, see Settings).
-- Short delay so the kill / arrival is on screen and not hidden behind a loot or zone popup.
function MCF:OnIconicFirst(id, detail)
    local def = byId[id]
    if not def then return end
    local german = self.GetLanguage and self:GetLanguage() == "deDE"
    -- Journal text: the personal first-person line; the plain description is the fallback (and stays in the achievements list).
    local story = german and (def.deStory or def.deDesc) or (def.enStory or def.enDesc)
    self:AutoMoment{reason = "ICONIC_" .. id, shotKey = "screenshotIconic", journalKey = "iconicJournal", delay = 1.5,
        title = german and def.de or def.en, text = story, source = "ICONIC", fields = {iconicID = id}}
    -- Popup after the screenshot (it must not be on the picture): moment name plus what triggered it.
    C_Timer.After(2.6, function()
        if MCF.ShowMomentToast then MCF:ShowMomentToast(german and def.de or def.en, MCF:IconicTriggerText(def.kind, detail)) end
    end)
end

-- "Defeated: Hogger", "Entered: Stormwind" ... (nil without a detail)
local TRIGGER = {
    kill    = {"Besiegt: %s", "Defeated: %s"},
    death   = {"Getötet von: %s", "Killed by: %s"},
    visit   = {"Betreten: %s", "Entered: %s"},
    talk    = {"Gespräch mit %s", "Spoke with %s"},
    quest   = {"Quest abgeschlossen: %s", "Quest completed: %s"},
    collect = {"Gefunden: %s", "Found: %s"},
    ride    = {"Bootsfahrt: %s", "Boat ride: %s"},
}
function MCF:IconicTriggerText(kind, detail)
    local t = TRIGGER[kind]
    if not t or type(detail) ~= "string" or detail == "" then return nil end
    return string.format((self.GetLanguage and self:GetLanguage() == "deDE") and t[1] or t[2], detail)
end

local function Remember(list, text)
    if type(text) ~= "string" or text == "" then return end
    for i = #list, 1, -1 do if list[i] == text then table.remove(list, i) end end
    list[#list + 1] = text
    while #list > RECENT_MAX do table.remove(list, 1) end
end

local function Matches(def, text)
    text = text:lower()
    for _, n in ipairs(def.names or {}) do
        if text:find(n, 1, true) then return true end
    end
    return false
end

local function Safe(v)
    local f = MCF.Readable
    if f then v = f(v) end
    if type(v) == "string" and v ~= "" then return v end
    return nil
end

---------------------------------------------------------------------------
-- Hooks called by the other modules
---------------------------------------------------------------------------
function MCF:OnIconicKill(name)
    name = Safe(name); if not name then return end
    Remember(recent.kills, name)
    for _, d in ipairs(MCF.IconicMoments) do
        if d.kind == "kill" and Matches(d, name) then Hit(d.id, nil, name) end
    end
end

function MCF:OnIconicDeath(name)
    name = Safe(name); if not name then return end
    Remember(recent.kills, name .. " (killer)")
    for _, d in ipairs(MCF.IconicMoments) do
        if d.kind == "death" and Matches(d, name) then Hit(d.id, nil, name) end
    end
end

---------------------------------------------------------------------------
-- Places and boat rides
---------------------------------------------------------------------------
local lastSeen = {}
local lastDock = nil
local scannedOnce = false   -- the first look after login/reload is not an entry: we may simply have logged in inside the city
local capitalById = {}
for _, d in ipairs(MCF.IconicMoments) do if d.capital then capitalById[d.id] = true end end

local function ScanPlaces()
    local zone, sub = Safe(GetZoneText and GetZoneText()), Safe(GetSubZoneText and GetSubZoneText())
    local now = GetTime()
    local seenNow = {}
    for _, text in ipairs({zone or "", sub or ""}) do
        if text ~= "" then
            Remember(recent.places, text)
            for _, d in ipairs(MCF.IconicMoments) do
                if d.kind == "visit" and Matches(d, text) then seenNow[d.id] = text end
            end
        end
    end
    -- A visit starts when we were not there at the previous look, and we have been away long enough
    -- (zoning in and out of a doorway is not a new visit).
    for id in pairs(seenNow) do
        local st = lastSeen[id]
        local away = st and not st.inside and now - st.leftAt > VISIT_GAP
        if not st or away then Hit(id, nil, seenNow[id]) end
        -- Capital visits: a real entry (we were elsewhere before); the very first sighting counts once if nothing was counted yet.
        if capitalById[id] and MCF.CountCapitalVisit then pcall(MCF.CountCapitalVisit, MCF, id, not ((not st and scannedOnce) or away)) end
        lastSeen[id] = {inside = true, leftAt = 0}
    end
    for id, st in pairs(lastSeen) do
        if st.inside and not seenNow[id] then st.inside, st.leftAt = false, now end
    end
    scannedOnce = true

    -- boats
    local here
    for _, text in ipairs({sub or "", zone or ""}) do
        local low = text:lower()
        for dock, words in pairs(DOCKS) do
            for _, w in ipairs(words) do
                if low ~= "" and low:find(w, 1, true) then here = dock end
            end
        end
    end
    if here then
        if lastDock and lastDock.name ~= here and now - lastDock.time <= RIDE_WINDOW then
            local a, b = lastDock.name, here
            if ROUTES[a .. "|" .. b] or ROUTES[b .. "|" .. a] then Hit("boat_ride", nil, DOCK_NAMES[a] .. " \226\134\146 " .. DOCK_NAMES[b]) end
        end
        lastDock = {name = here, time = now}
    end
end

---------------------------------------------------------------------------
-- Talking to an NPC (leaders of the capitals): the name of the conversation partner while a gossip or quest window is open
---------------------------------------------------------------------------
local function OnTalk()
    local name = Safe(UnitName and UnitName("npc"))
    if not name then return end
    Remember(recent.npcs, name)
    for _, d in ipairs(MCF.IconicMoments) do
        if d.kind == "talk" and Matches(d, name) then Hit(d.id, nil, name) end
    end
end

---------------------------------------------------------------------------
-- Quests and loot
---------------------------------------------------------------------------
local function OnQuest(questID)
    local title = C_QuestLog and C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(questID)
    title = Safe(title); if not title then return end
    Remember(recent.items, "quest: " .. title)
    local low = title:lower()
    for _, d in ipairs(MCF.IconicMoments) do
        if d.kind == "quest" and ((d.pattern and low:find(d.pattern)) or (d.patternDe and low:find(d.patternDe))) then Hit(d.id, nil, title) end
    end
end

-- "Die Grünen Hügel von Schlingendorn - Seite 7" / "Green Hills of Stranglethorn - Page 7"
local function OnLoot(message)
    message = Safe(message); if not message then return end
    local name = message:match("%[([^%]]+)%]")
    if not name then return end
    local low = name:lower()
    if low:find("green hills of stranglethorn", 1, true) or low:find("grünen hügel", 1, true) or low:find("gruenen huegel", 1, true) then
        local page = low:match("page%s*(%d+)") or low:match("seite%s*(%d+)")
        if page then
            Remember(recent.items, name)
            Hit("green_pages", page, name)
        end
    end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local frame = CreateFrame("Frame")
for _, e in ipairs({"PLAYER_ENTERING_WORLD", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA",
                    "QUEST_TURNED_IN", "CHAT_MSG_LOOT", "GOSSIP_SHOW", "QUEST_GREETING", "QUEST_DETAIL", "QUEST_PROGRESS"}) do
    pcall(function() frame:RegisterEvent(e) end)
end
frame:SetScript("OnEvent", function(_, event, ...)
    if event == "QUEST_TURNED_IN" then pcall(OnQuest, (...))
    elseif event == "GOSSIP_SHOW" or event == "QUEST_GREETING" or event == "QUEST_DETAIL" or event == "QUEST_PROGRESS" then pcall(OnTalk)
    elseif event == "CHAT_MSG_LOOT" then
        local message, _, _, _, player = ...
        -- own loot only: the player field is our name, or empty on clients that don't send it
        local me = Safe(UnitName and UnitName("player"))
        local who = Safe(player)
        if not who or who == "" or (me and who:match("^[^-]+") == me) then pcall(OnLoot, message) end
    else
        C_Timer.After(0.5, function() pcall(ScanPlaces) end)
    end
end)

---------------------------------------------------------------------------
-- Summary for UI, achievements and export
---------------------------------------------------------------------------
function MCF:GetIconicList()
    local list, m = {}, Store() or {}
    for _, d in ipairs(MCF.IconicMoments) do
        local e = m[d.id]
        local done = e and (e.count or 0) > 0
        local progress, total
        if d.kind == "collect" then
            progress = 0
            for _ in pairs(e and e.set or {}) do progress = progress + 1 end
            total = d.total
            done = progress >= (d.total or 1)
        end
        list[#list + 1] = {def = d, entry = e, found = e and (e.count or 0) > 0, done = done, progress = progress, total = total}
    end
    return list
end

-- Localized title of a moment (map pins of screenshots without a journal entry).
function MCF:GetIconicTitle(id)
    local d = byId[id]
    if not d then return nil end
    return (self.GetLanguage and self:GetLanguage() == "deDE") and d.de or d.en
end

function MCF:GetIconicFound()
    local n = 0
    for _, row in ipairs(self:GetIconicList()) do if row.found then n = n + 1 end end
    return n, #MCF.IconicMoments
end

-- Test unlock of one moment (collections are filled up with test keys). Returns true, or false plus a reason.
function MCF:IconicDebugUnlock(id, quiet)
    local d = byId[id]
    if not d then return false, "unknown" end
    if not self:IconicEnabled() then return false, "off" end
    local e = Entry(id)
    local done = false
    for _, row in ipairs(self:GetIconicList()) do if row.def.id == id then done = row.done end end
    if done then return false, "already" end
    forceTest, quietTest = true, quiet and true or false
    local ok, err = pcall(function()
        if d.kind == "collect" then
            local have = 0
            for _ in pairs(e.set or {}) do have = have + 1 end
            for i = 1, math.max(0, (d.total or 1) - have) do Hit(id, "test" .. i, "test") end
        else
            Hit(id, nil, nil)
        end
    end)
    forceTest, quietTest = false, false
    if not ok then return false, tostring(err) end
    return true
end

-- Removes every test unlock again: moments (and test keys of collections) plus their timeline events.
function MCF:IconicDebugReset()
    local m, n = Store(), 0
    for id, e in pairs(m or {}) do
        if e.first and e.first.test then m[id] = nil; n = n + 1
        elseif e.set then
            local drop = 0
            for k in pairs(e.set) do if type(k) == "string" and k:match("^test%d+$") then e.set[k] = nil; drop = drop + 1 end end
            if drop > 0 then e.count = math.max(0, (e.count or 0) - drop); n = n + 1 end
        end
    end
    local ev = MyCharForeverDB and MyCharForeverDB.events
    if ev then
        for i = #ev, 1, -1 do local d = ev[i].data; if ev[i].type == "ICONIC" and type(d) == "table" and d.test then table.remove(ev, i) end end
    end
    if self.RefreshUI then self:RefreshUI() end
    return n
end

MCF:AddCommand{group="debug", usage="/mcf iconic [list|unlock <id|all>|reset]", example="/mcf iconic unlock all",
    de="Ikonische Momente: Erkennung prüfen; \"unlock\" schaltet Momente zum Testen frei (markiert als Test), \"reset\" entfernt sie wieder",
    en="Iconic moments: check the matching; \"unlock\" unlocks moments for testing (marked as test), \"reset\" removes them again",
    match=function(msg) return msg == "iconic" or msg:match("^iconic%s+%S") ~= nil end,
    run=function(msg)
        local german = MCF.GetLanguage and MCF:GetLanguage() == "deDE"
        local function say(t) print("|cff00ccffMyCharForever|r: " .. t) end
        local sub, arg = msg:match("^iconic%s+(%S+)%s*(.-)%s*$")
        if sub == "list" then
            local missing = {}
            for _, row in ipairs(MCF:GetIconicList()) do if not row.done then missing[#missing + 1] = row.def.id end end
            say((german and "Noch nicht frei: " or "Not unlocked yet: ") .. (#missing > 0 and table.concat(missing, ", ") or "-"))
        elseif sub == "unlock" and arg ~= "" then
            local ids = {}
            if arg:lower() == "all" then
                for _, d in ipairs(MCF.IconicMoments) do ids[#ids + 1] = d.id end
            elseif byId[arg] then ids[1] = arg
            else
                for _, d in ipairs(MCF.IconicMoments) do if d.id:find(arg:lower(), 1, true) then ids[#ids + 1] = d.id end end
                if #ids > 1 then say((german and "Mehrdeutig, passt auf: " or "Ambiguous, matches: ") .. table.concat(ids, ", ")); return end
            end
            if #ids == 0 then say(german and "Unbekannter Moment. /mcf iconic list zeigt die Namen." or "Unknown moment. /mcf iconic list shows the names."); return end
            local n = 0
            for _, id in ipairs(ids) do
                local ok, why = MCF:IconicDebugUnlock(id, #ids > 1)
                if ok then n = n + 1
                elseif why == "off" then say(german and "Ikonische Momente sind in den Einstellungen ausgeschaltet." or "Iconic moments are switched off in the settings."); return end
            end
            say((german and "%d Moment(e) als Test freigeschaltet (nur Popup, kein Screenshot, kein Tagebuch). Entfernen: /mcf iconic reset"
                or "%d moment(s) unlocked as test (popup only, no screenshot, no journal). Remove: /mcf iconic reset"):format(n))
        elseif sub == "reset" then
            say((german and "%d Test-Freischaltung(en) entfernt." or "%d test unlock(s) removed."):format(MCF:IconicDebugReset()))
        else
            local found, total = MCF:GetIconicFound()
            say(found .. " / " .. total)
            print("  kills: " .. (#recent.kills > 0 and table.concat(recent.kills, ", ") or "-"))
            print("  places: " .. (#recent.places > 0 and table.concat(recent.places, ", ") or "-"))
            print("  items: " .. (#recent.items > 0 and table.concat(recent.items, ", ") or "-"))
            print("  npcs: " .. (#recent.npcs > 0 and table.concat(recent.npcs, ", ") or "-"))
        end
    end}
