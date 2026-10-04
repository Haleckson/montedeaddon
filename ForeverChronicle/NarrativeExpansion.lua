-- Additional, locale-matched diary prose for Forever Chronicle.
-- The compact matrices below expand into distinct, selectable sentence forms.
local _, namespace = ...
local FC = namespace.FC
local L = FC.L

local language = (GetLocale and GetLocale() == "deDE") and "deDE" or "enUS"

local banks = {
    enUS = {
        DIARY_CONTINENT = {
            start = 25,
            heads = {
                "I crossed onto the continent of “%s”",
                "The shores of “%s” came into view",
                "My travels carried me to “%s”",
                "I set foot on “%s” for the first time",
                "A new horizon opened over “%s”",
                "The name “%s” became a place beneath my feet",
            },
            tails = {
                ", and its roads now belong to my own memories.",
                "; the lands beyond the coast still lay ahead.",
                ", with a whole new stretch of Azeroth before me.",
                ", turning a distant name into part of my journey.",
            },
        },
        DIARY_ZONE = {
            start = 25,
            heads = {
                "I entered “%s”",
                "The road brought me into “%s”",
                "I reached “%s” for the first time",
                "“%s” appeared on my own map at last",
                "My path led across the border into “%s”",
                "I left familiar roads behind and came to “%s”",
            },
            tails = {
                ", a new name among the places I have walked.",
                "; its trails were still waiting to be learned.",
                ", and made its first mark on my travels.",
                ", where the next part of the road began.",
            },
        },
        DIARY_SUBZONE = {
            start = 21,
            heads = {
                "Within %s, I discovered %s",
                "My travels through %s brought me to %s",
                "I found a new landmark in %s: %s",
                "The paths of %s led me to %s",
                "While travelling through %s, I reached %s",
            },
            tails = {
                ", a smaller place now held in my memory.",
                "; its name has a place on my map now.",
                ", another corner of the land made real by the journey.",
                ", a detail that gives this corner of the region its own character.",
            },
        },
        DIARY_QUEST_ACCEPTED = {
            start = 25,
            heads = {
                "I accepted the charge “%s”",
                "The task “%s” became part of my day",
                "I agreed to see “%s” through",
                "A new undertaking began with “%s”",
                "I took “%s” onto my list of duties",
                "The request called “%s” found its way to me",
            },
            tails = {
                ", with its outcome still ahead of me.",
                "; the next step would have to wait for the road.",
                ", one more promise to carry through Azeroth.",
                ", and set out knowing there was work to do.",
            },
        },
        DIARY_QUEST_COMPLETED = {
            start = 25,
            heads = {
                "I brought “%s” to its end",
                "The work of “%s” was finished",
                "I saw “%s” through to completion",
                "“%s” reached its final page on my watch",
                "I completed the undertaking known as “%s”",
                "The last task of “%s” was behind me",
            },
            tails = {
                ", and could finally turn toward what came next.",
                "; one more promise had been kept.",
                ", a completed chapter in the day's travels.",
                ", leaving the road open for another purpose.",
            },
        },
        DIARY_SHARED_QUEST = {
            start = 15,
            heads = {
                "With %s beside me, I completed “%s”",
                "%s shared the road as I finished “%s”",
                "Together with %s, I saw “%s” through",
                "With %s at my side, the work of “%s” reached its end",
                "With %s beside me, I closed the chapter of “%s”",
                "%s stood with me when “%s” was completed",
                "With %s beside me, our path through “%s” reached its end",
            },
            tails = {
                ", a task we did not face alone.",
                "; the memory of that road includes us both.",
            },
        },
        DIARY_LEVEL = {
            start = 21,
            heads = {
                "I reached level %s",
                "Level %s marked my progress",
                "My experience carried me to level %s",
                "I advanced to level %s",
                "The next milestone was level %s",
            },
            tails = {
                ", proof that the road had changed me.",
                "; new challenges now lay within reach.",
                ", another measure of how far I had come.",
                ", and the journey continued from a stronger footing.",
            },
        },
        DIARY_DUNGEON = {
            start = 21,
            heads = {
                "I entered %s",
                "The way down led into %s",
                "My travels took me inside %s",
                "I crossed the threshold of %s",
                "The entrance to %s opened before me",
            },
            tails = {
                ", where the next stretch of the journey turned inward.",
                "; the record remembers this as an instance visit.",
                ", leaving the open road behind for a time.",
                ", with its depths still ahead of me.",
            },
        },
        DIARY_SHARED_DUNGEON = {
            start = 21,
            heads = {
                "With %s, I entered %s",
                "%s joined me on the way into %s",
                "With %s beside me, I crossed into %s",
                "With %s beside me, I took the road into %s",
                "Together with %s, I stepped inside %s",
            },
            tails = {
                ", a descent recorded in company.",
                "; we left the daylight road behind us.",
                ", and faced the instance as a group.",
                ", with the next part of the journey ahead.",
            },
        },
        DIARY_RARE = {
            start = 25,
            heads = {
                "I encountered the rare creature %s",
                "A rare presence crossed my path: %s",
                "I came upon %s, a rare creature",
                "The name %s entered my record of rare encounters",
                "I saw %s during my travels, a rare creature",
                "One unusual encounter brought me face to face with %s",
            },
            tails = {
                ", a meeting worth keeping in the chronicle.",
                "; its presence made this stretch of road stand out.",
                ", an uncommon sight along the way.",
                ", a rare moment among ordinary miles.",
            },
        },
        DIARY_GATHER = {
            start = 21,
            heads = {
                "I gathered %s along the way",
                "My travels yielded %s",
                "I found a source of %s and collected it",
                "The day's gathering brought me %s",
                "I stopped to gather %s",
            },
            tails = {
                ", one more resource remembered from this place.",
                "; a useful find for the road ahead.",
                ", and noted where the find had been made.",
                ", a small discovery between larger events.",
            },
        },
        DIARY_ITEM_LOOT = {
            start = 21,
            heads = {
                "I found %s among the spoils",
                "The day's travels brought %s into my hands",
                "I recovered %s during the journey",
                "%s became part of what I carried away",
                "I came away with %s",
            },
            tails = {
                ", a find tied to the events of the road.",
                "; its place in the record is marked.",
                ", one more detail from this part of the adventure.",
                ", remembered alongside the place where it appeared.",
            },
        },
        DIARY_ITEM_VENDOR = {
            start = 21,
            heads = {
                "I bought %s from a vendor",
                "A merchant's stock yielded %s",
                "I added %s to my pack after a purchase",
                "The day's trade brought me %s",
                "I left the stall carrying %s",
            },
            tails = {
                ", a small exchange along the way.",
                "; the seller's wares became part of the journey.",
                ", with the purchase recorded among my finds.",
                ", a practical stop between stretches of travel.",
            },
        },
        DIARY_ITEM = {
            start = 21,
            heads = {
                "I noted %s among the items encountered",
                "%s found a place in my growing item record",
                "My travels brought %s to my attention",
                "I came across %s during this part of the journey",
                "The chronicle added %s to its remembered items",
            },
            tails = {
                ", linked to the place where it was seen.",
                "; its name is no longer lost to memory.",
                ", one more detail preserved for another day.",
                ", a quiet note among the day's larger moments.",
            },
        },
        DIARY_NPC_DISCOVERY = {
            start = 21,
            heads = {
                "I met %s along the way",
                "%s entered my memory of this journey",
                "My path crossed with %s",
                "I encountered %s during my travels",
                "The name %s became part of this day's record",
            },
            tails = {
                ", another face tied to this place.",
                "; the meeting now has a place in my notes.",
                ", a brief encounter preserved for later.",
                ", one more name to remember from the road.",
            },
        },
        DIARY_DEATH = {
            start = 21,
            heads = {
                "The fight ended with me fallen",
                "I did not leave that battle standing",
                "The day's road included a defeat",
                "I fell before the struggle was over",
                "That encounter brought me down",
            },
            tails = {
                ", and the journey paused there.",
                "; I still had to find my way back.",
                ", a hard turn in the day's account.",
                ", proof that not every road is won.",
            },
        },
        DIARY_RESURRECTION = {
            start = 21,
            heads = {
                "I returned to the living",
                "Life found me again",
                "I rose and resumed the journey",
                "The veil lifted, and I was back",
                "I returned from the spirit world",
            },
            tails = {
                ", with more road still ahead.",
                "; the story had not reached its end.",
                ", and continued from where I could.",
                ", carrying the memory of the fall with me.",
            },
        },
        DIARY_HEALTH_RECOVERY = {
            start = 11,
            heads = {
                "My health began to return",
                "I recovered some strength",
                "A short pause let my wounds settle",
                "I felt my strength return",
                "My condition improved for a while",
            },
            tails = {
                ", enough to continue the day's road.",
                "; I could take a steadier breath.",
            },
        },
        DIARY_EAT = {
            start = 11,
            heads = {
                "I stopped to eat",
                "A meal interrupted the road",
                "I took a moment for food",
                "I ate before setting out again",
                "The day's journey included a meal break",
            },
            tails = {
                ", then returned to the path.",
                "; even a traveler must pause.",
            },
        },
        DIARY_DRINK = {
            start = 11,
            heads = {
                "I paused for a drink",
                "I stopped to quench my thirst",
                "A drink gave me a brief pause",
                "I took a moment to drink",
                "The road made room for a drink break",
            },
            tails = {
                ", then continued on.",
                "; the next stretch could wait a moment.",
            },
        },
        DIARY_NOTE = {
            start = 21,
            heads = {
                "I wrote this down: “%s”",
                "A thought from the road stayed with me: “%s”",
                "I left these words on the page: “%s”",
                "This detail deserved a place in my memory: “%s”",
                "Before moving on, I noted: “%s”",
            },
            tails = {
                ", so I would find it again.",
                "; some moments are best kept in my own words.",
                ", a small mark beside the day's events.",
                ", preserved for the next time I look back.",
            },
        },
        DIARY_COMPANIONS = {
            start = 21,
            heads = {
                "I shared the road with %s",
                "%s became part of this journey",
                "For a time, %s travelled beside me",
                "My path crossed with %s, and we travelled together",
                "I was not alone on the road with %s",
            },
            tails = {
                ", a name I wanted the chronicle to keep.",
                "; the company changed the feel of the journey.",
                ", remembered as part of this stretch of road.",
                ", one of the people who shared the day.",
            },
        },
        DIARY_MERCHANT = {
            start = 21,
            heads = {
                "I visited %s in %s, whose trade was %s",
                "I sought out %s in %s for %s",
                "My route brought me to %s in %s, a seller of %s",
                "I found %s in %s, dealing in %s",
                "I reached %s in %s, where I found %s",
            },
            tails = {
                ", a useful name to remember for another visit.",
                "; the location and trade are now kept together.",
                ", one more familiar face in the local streets.",
                ", a practical stop recorded along the way.",
            },
        },
        DIARY_TRAINER = {
            start = 21,
            heads = {
                "I sought instruction from %s",
                "I visited %s to learn from a trainer",
                "My travels brought me to trainer %s",
                "I found %s and sought training",
                "The day's path led me to %s for instruction",
            },
            tails = {
                ", keeping the teacher's name with the place.",
                "; a useful stop for a growing adventurer.",
                ", an encounter worth finding again.",
                ", another name added to my memory of the world.",
            },
        },
        DIARY_RETURN = {
            start = 13,
            heads = {
                "%s, I returned to %s",
                "By %s, my steps had brought me back to %s",
                "%s found me once more in %s",
                "By %s, I made my way back to %s",
                "When %s arrived, I was again in %s",
                "By %s, I had returned to %s",
            },
            tails = {
                ", closing a path I had walked before.",
                "; the day's route had come full circle.",
            },
        },
        DIARY_KILL_GROUP = {
            start = 21,
            heads = {
                "%d foes fell during the fighting, including %s",
                "I overcame %d enemies on the road, among them %s",
                "The day's battles accounted for %d foes; I remember %s",
                "Across the journey, I defeated %d opponents, including %s",
                "%d enemies stood in my way, and %s were among them",
            },
            tails = {
                ", part of the day's hard-won progress.",
                "; each encounter marked another stretch of the road.",
                ", names preserved from the fighting.",
                ", a record of the battles that crossed my path.",
            },
        },
        DIARY_OPEN = {
            start = 21,
            heads = {
                "I set out %s from “%s”",
                "The day's travels began %s in “%s”",
                "%s, I resumed the road from “%s”",
                "My journey opened %s in “%s”",
                "I began this recorded stretch %s at “%s”",
            },
            tails = {
                ", with the next page still unwritten.",
                "; whatever lay ahead had yet to be seen.",
                ", carrying no map of the moments to come.",
                ", ready to see where the road would lead.",
            },
        },
        DIARY_END = {
            start = 21,
            heads = {
                "%s, I brought the day to a close in “%s”",
                "The last recorded stop came %s in “%s”",
                "I paused the journey %s at “%s”",
                "%s, my travels ended for now in “%s”",
                "I left the road for the moment %s in “%s”",
            },
            tails = {
                ", leaving the next mile for another day.",
                "; the chronicle can take up the road again later.",
                ", with the day's events safely kept on the page.",
                ", and let the day's account come to rest.",
            },
        },
    },
    deDE = {
        DIARY_CONTINENT = {
            start = 25,
            heads = {
                "Ich betrat zum ersten Mal den Kontinent „%s“",
                "Die Küste von „%s“ kam in Sicht",
                "Meine Reise führte mich nach „%s“",
                "Ich setzte erstmals meinen Fuß auf „%s“",
                "Über „%s“ öffnete sich ein neuer Horizont",
                "Der Name „%s“ wurde zu einem Ort unter meinen Füßen",
            },
            tails = {
                ", und seine Wege gehören nun zu meinen Erinnerungen.",
                "; das Land jenseits der Küste lag noch vor mir.",
                ", eine neue Weite Azeroths lag vor mir.",
                ", ein ferner Name wurde Teil meiner eigenen Reise.",
            },
        },
        DIARY_ZONE = {
            start = 25,
            heads = {
                "Ich betrat „%s“",
                "Der Weg führte mich nach „%s“",
                "Ich erreichte zum ersten Mal „%s“",
                "„%s“ erschien endlich auf meiner eigenen Karte",
                "Mein Weg führte mich über die Grenze nach „%s“",
                "Ich ließ vertraute Wege hinter mir und kam nach „%s“",
            },
            tails = {
                ", ein neuer Name unter den Orten, die ich selbst betreten habe.",
                "; seine Pfade musste ich erst noch kennenlernen.",
                ", und hinterließ damit die erste Spur in meiner Reise.",
                ", wo ein neuer Abschnitt des Weges begann.",
            },
        },
        DIARY_SUBZONE = {
            start = 21,
            heads = {
                "In %s entdeckte ich %s",
                "Meine Wege durch %s führten mich nach %s",
                "Ich fand in %s einen neuen Orientierungspunkt: %s",
                "Die Pfade von %s brachten mich nach %s",
                "Auf meinem Weg durch %s erreichte ich %s",
            },
            tails = {
                ", ein kleinerer Ort, der nun Teil meiner Erinnerung ist.",
                "; sein Name steht jetzt auf meiner eigenen Karte.",
                ", eine weitere Ecke des Landes wurde durch die Reise vertraut.",
                ", ein Detail, das diesem Gebiet seinen eigenen Charakter gibt.",
            },
        },
        DIARY_QUEST_ACCEPTED = {
            start = 25,
            heads = {
                "Ich nahm den Auftrag „%s“ an",
                "Die Aufgabe „%s“ wurde Teil meines Tages",
                "Ich versprach, mich um „%s“ zu kümmern",
                "Mit „%s“ begann ein neues Vorhaben",
                "Ich nahm „%s“ in meine Pflichten auf",
                "Die Bitte namens „%s“ erreichte mich",
            },
            tails = {
                ", das Ergebnis lag noch vor mir.",
                "; der nächste Schritt musste bis zum Weg warten.",
                ", ein weiteres Versprechen, das mich durch Azeroth begleitete.",
                ", und machte mich an die Arbeit.",
            },
        },
        DIARY_QUEST_COMPLETED = {
            start = 25,
            heads = {
                "Ich brachte „%s“ zu einem Abschluss",
                "Die Arbeit an „%s“ war getan",
                "Ich führte „%s“ bis zum Ende aus",
                "„%s“ schlug unter meiner Hand die letzte Seite auf",
                "Ich schloss das Vorhaben „%s“ ab",
                "Die letzte Aufgabe von „%s“ lag hinter mir",
            },
            tails = {
                ", und konnte mich endlich dem nächsten Wegstück widmen.",
                "; ein weiteres Versprechen war erfüllt.",
                ", ein abgeschlossenes Kapitel dieses Tages.",
                ", und der Weg war frei für ein neues Vorhaben.",
            },
        },
        DIARY_SHARED_QUEST = {
            start = 15,
            heads = {
                "Gemeinsam mit %s schloss ich „%s“ ab",
                "%s teilte den Weg mit mir, als ich „%s“ beendete",
                "Mit %s an meiner Seite brachte ich „%s“ zu Ende",
                "Mit %s an meiner Seite kam die Arbeit an „%s“ zu einem Ende",
                "Zusammen mit %s schloss ich das Kapitel „%s“",
                "%s stand mir bei, als „%s“ abgeschlossen wurde",
                "Mit %s an meiner Seite erreichte unser Weg durch „%s“ sein Ende",
            },
            tails = {
                ", eine Aufgabe, der wir uns nicht allein stellten.",
                "; auch unsere gemeinsame Reise gehört zu dieser Erinnerung.",
            },
        },
        DIARY_LEVEL = {
            start = 21,
            heads = {
                "Ich erreichte Stufe %s",
                "Stufe %s markierte meinen Fortschritt",
                "Meine Erfahrung brachte mich auf Stufe %s",
                "Ich stieg auf Stufe %s auf",
                "Der nächste Meilenstein war Stufe %s",
            },
            tails = {
                ", ein Zeichen dafür, wie weit ich gekommen war.",
                "; neue Herausforderungen rückten in Reichweite.",
                ", ein weiterer Maßstab für meinen Weg.",
                ", und ich setzte meine Reise mit neuen Kräften fort.",
            },
        },
        DIARY_DUNGEON = {
            start = 21,
            heads = {
                "Ich betrat %s",
                "Der Abstieg führte nach %s",
                "Meine Reise führte mich hinein nach %s",
                "Ich überschritt die Schwelle zu %s",
                "Der Eingang zu %s lag vor mir",
            },
            tails = {
                ", der nächste Wegabschnitt führte diesmal in die Tiefe.",
                "; die Chronik hält diesen Besuch als Instanz fest.",
                ", und ließ die offenen Straßen eine Weile hinter mir.",
                ", während die Tiefen noch vor mir lagen.",
            },
        },
        DIARY_SHARED_DUNGEON = {
            start = 21,
            heads = {
                "Gemeinsam mit %s betrat ich %s",
                "%s begleitete mich auf dem Weg nach %s",
                "Mit %s an meiner Seite zog ich nach %s",
                "Mit %s an meiner Seite führte mich der Weg nach %s",
                "Zusammen mit %s trat ich in %s ein",
            },
            tails = {
                ", ein Abstieg, den ich nicht allein auf mich nahm.",
                "; gemeinsam ließen wir das Tageslicht hinter uns.",
                ", und stellten uns der Instanz als Gruppe.",
                ", der nächste Abschnitt lag vor uns.",
            },
        },
        DIARY_RARE = {
            start = 25,
            heads = {
                "Ich begegnete dem seltenen Wesen %s",
                "Eine seltene Begegnung kreuzte meinen Weg: %s",
                "Ich traf unterwegs auf %s, ein seltenes Wesen",
                "Der Name %s kam in meine Aufzeichnungen seltener Begegnungen",
                "Auf meiner Reise sah ich %s, ein seltenes Wesen",
                "Eine ungewöhnliche Begegnung führte mich zu %s",
            },
            tails = {
                ", eine Begegnung, die einen Platz in der Chronik verdient.",
                "; seine Anwesenheit machte diesen Wegabschnitt besonders.",
                ", ein seltener Anblick am Wegesrand.",
                ", ein besonderer Moment zwischen gewöhnlichen Meilen.",
            },
        },
        DIARY_GATHER = {
            start = 21,
            heads = {
                "Unterwegs sammelte ich %s",
                "Meine Reise brachte mir %s ein",
                "Ich fand eine Quelle von %s und sammelte davon",
                "Bei meinen Sammelfunden kam %s hinzu",
                "Ich hielt an, um %s zu sammeln",
            },
            tails = {
                ", ein weiterer Fund, den ich mit diesem Ort verbinde.",
                "; nützlich für den Weg, der noch vor mir lag.",
                ", und hielt fest, wo ich den Fund gemacht hatte.",
                ", eine kleine Entdeckung zwischen größeren Erlebnissen.",
            },
        },
        DIARY_ITEM_LOOT = {
            start = 21,
            heads = {
                "Unter der Beute fand ich %s",
                "Die Reise brachte %s in meine Hände",
                "Unterwegs erbeutete ich %s",
                "%s gehörte zu dem, was ich mitnahm",
                "Ich kam mit %s zurück",
            },
            tails = {
                ", ein Fund, der zu den Ereignissen des Weges gehört.",
                "; auch dieser Gegenstand ist nun verzeichnet.",
                ", ein weiteres Detail aus diesem Abenteuer.",
                ", verbunden mit dem Ort, an dem er auftauchte.",
            },
        },
        DIARY_ITEM_VENDOR = {
            start = 21,
            heads = {
                "Bei einem Händler kaufte ich %s",
                "Im Angebot eines Händlers fand ich %s",
                "Nach einem Einkauf gehörte %s zu meinem Gepäck",
                "Der Handel des Tages brachte mir %s ein",
                "Ich verließ den Stand mit %s",
            },
            tails = {
                ", ein kleiner Tausch am Wegesrand.",
                "; die Waren des Händlers wurden Teil meiner Reise.",
                ", der Kauf steht nun bei meinen Funden.",
                ", ein praktischer Halt zwischen zwei Wegstücken.",
            },
        },
        DIARY_ITEM = {
            start = 21,
            heads = {
                "Ich vermerkte %s unter den begegneten Gegenständen",
                "%s fand einen Platz in meinem wachsenden Gegenstandsarchiv",
                "Unterwegs wurde ich auf %s aufmerksam",
                "In diesem Reiseabschnitt begegnete mir %s",
                "Die Chronik nahm %s in ihre Gegenstandserinnerungen auf",
            },
            tails = {
                ", verknüpft mit dem Ort, an dem ich es gesehen hatte.",
                "; sein Name ist nun nicht mehr vergessen.",
                ", ein weiteres Detail, das ich für später bewahre.",
                ", eine ruhige Notiz zwischen den größeren Erlebnissen.",
            },
        },
        DIARY_NPC_DISCOVERY = {
            start = 21,
            heads = {
                "Unterwegs begegnete ich %s",
                "%s fand Eingang in meine Erinnerung an diese Reise",
                "Mein Weg kreuzte sich mit %s",
                "Auf meinen Reisen traf ich auf %s",
                "Der Name %s wurde Teil der heutigen Aufzeichnungen",
            },
            tails = {
                ", ein weiteres Gesicht, das zu diesem Ort gehört.",
                "; die Begegnung ist nun in meinen Notizen bewahrt.",
                ", ein kurzer Kontakt, den ich später wiederfinden kann.",
                ", ein weiterer Name, den ich vom Weg mitnehme.",
            },
        },
        DIARY_DEATH = {
            start = 21,
            heads = {
                "Der Kampf endete damit, dass ich fiel",
                "Aus diesem Gefecht ging ich nicht aufrecht hervor",
                "Auch eine Niederlage gehörte zum Weg dieses Tages",
                "Noch vor dem Ende des Kampfes ging ich zu Boden",
                "Diese Begegnung brachte mich zu Fall",
            },
            tails = {
                ", und meine Reise hielt dort kurz inne.",
                "; ich musste erst den Weg zurückfinden.",
                ", eine harte Wendung in den Ereignissen des Tages.",
                ", denn nicht jeder Weg endet mit einem Sieg.",
            },
        },
        DIARY_RESURRECTION = {
            start = 21,
            heads = {
                "Ich kehrte zu den Lebenden zurück",
                "Das Leben fand zu mir zurück",
                "Ich erhob mich und setzte meine Reise fort",
                "Der Schleier hob sich, und ich war zurück",
                "Ich kehrte aus der Geisterwelt zurück",
            },
            tails = {
                ", und noch lag ein Wegstück vor mir.",
                "; meine Geschichte war noch nicht zu Ende.",
                ", und machte dort weiter, wo es mir möglich war.",
                ", die Erinnerung an meinen Sturz im Gepäck.",
            },
        },
        DIARY_HEALTH_RECOVERY = {
            start = 11,
            heads = {
                "Meine Gesundheit kehrte langsam zurück",
                "Ich gewann einen Teil meiner Kraft zurück",
                "Eine kurze Pause ließ meine Wunden etwas ruhen",
                "Ich spürte, wie meine Kräfte zurückkehrten",
                "Mein Zustand besserte sich für einen Moment",
            },
            tails = {
                ", genug, um den Weg des Tages fortzusetzen.",
                "; ich konnte wieder ruhiger Atem holen.",
            },
        },
        DIARY_EAT = {
            start = 11,
            heads = {
                "Ich hielt an, um zu essen",
                "Eine Mahlzeit unterbrach meinen Weg",
                "Ich nahm mir einen Moment für etwas zu essen",
                "Vor dem nächsten Aufbruch aß ich etwas",
                "Zum Tag gehörte auch eine Essenspause",
            },
            tails = {
                ", danach kehrte ich auf den Pfad zurück.",
                "; auch Reisende müssen einmal rasten.",
            },
        },
        DIARY_DRINK = {
            start = 11,
            heads = {
                "Ich machte eine Trinkpause",
                "Ich hielt an, um meinen Durst zu stillen",
                "Ein Schluck verschaffte mir einen kurzen Halt",
                "Ich nahm mir einen Moment zum Trinken",
                "Der Weg ließ Raum für eine kurze Trinkpause",
            },
            tails = {
                ", dann zog ich weiter.",
                "; der nächste Wegabschnitt konnte kurz warten.",
            },
        },
        DIARY_NOTE = {
            start = 21,
            heads = {
                "Ich schrieb es auf: „%s“",
                "Ein Gedanke vom Weg blieb mir: „%s“",
                "Diese Worte ließ ich auf der Seite zurück: „%s“",
                "Dieses Detail verdiente einen Platz in meiner Erinnerung: „%s“",
                "Bevor ich weiterzog, hielt ich fest: „%s“",
            },
            tails = {
                ", damit ich es wiederfinden kann.",
                "; manche Augenblicke bewahre ich am liebsten in eigenen Worten.",
                ", eine kleine Notiz neben den Ereignissen des Tages.",
                ", für den nächsten Blick zurück aufgehoben.",
            },
        },
        DIARY_COMPANIONS = {
            start = 21,
            heads = {
                "Ich teilte den Weg mit %s",
                "%s wurde Teil dieser Reise",
                "Eine Weile zog %s an meiner Seite mit",
                "Mein Weg kreuzte sich mit %s, und wir reisten gemeinsam",
                "Mit %s war ich auf dem Weg nicht allein",
            },
            tails = {
                ", ein Name, den die Chronik bewahren soll.",
                "; die Gesellschaft veränderte den Charakter der Reise.",
                ", als Teil dieses Wegstücks in Erinnerung behalten.",
                ", einer der Menschen, mit denen ich den Tag teilte.",
            },
        },
        DIARY_MERCHANT = {
            start = 21,
            heads = {
                "Ich besuchte %s in %s, wo %s gehandelt wurde",
                "Ich suchte %s in %s wegen des Angebots an %s auf",
                "Mein Weg führte mich zu %s in %s, einem Händler für %s",
                "Ich fand %s in %s, wo es um %s ging",
                "Ich erreichte %s in %s, wo es um %s ging",
            },
            tails = {
                ", ein nützlicher Name für einen späteren Besuch.",
                "; Ort und Angebot bleiben gemeinsam verzeichnet.",
                ", ein weiteres vertrautes Gesicht in den Straßen.",
                ", ein praktischer Halt auf meinem Weg.",
            },
        },
        DIARY_TRAINER = {
            start = 21,
            heads = {
                "Ich suchte bei %s nach Unterweisung",
                "Ich besuchte %s, um bei einem Lehrer zu lernen",
                "Meine Reise führte mich zu Ausbilder %s",
                "Ich fand %s und ließ mich ausbilden",
                "Der Weg des Tages führte mich für eine Lektion zu %s",
            },
            tails = {
                ", gemeinsam mit dem Ort im Gedächtnis behalten.",
                "; ein nützlicher Halt für jemanden auf Wanderschaft.",
                ", eine Begegnung, die ich wiederfinden möchte.",
                ", ein weiterer Name aus meiner Erinnerung an die Welt.",
            },
        },
        DIARY_RETURN = {
            start = 13,
            heads = {
                "%s kehrte ich nach %s zurück",
                "Gegen %s hatten mich meine Schritte wieder nach %s geführt",
                "%s fand ich mich erneut in %s wieder",
                "Ich kehrte %s nach %s zurück",
                "Als es %s wurde, war ich wieder in %s",
                "%s machte ich mich auf den Rückweg nach %s",
            },
            tails = {
                ", ein bereits begangener Weg schloss sich damit.",
                "; die Route des Tages führte wieder zum Ausgangspunkt.",
            },
        },
        DIARY_KILL_GROUP = {
            start = 21,
            heads = {
                "Im Kampf fielen %d Gegner, darunter %s",
                "Auf dem Weg besiegte ich %d Feinde, darunter %s",
                "Die Kämpfe des Tages forderten %d Gegner; ich erinnere mich an %s",
                "Auf meiner Reise bezwang ich %d Widersacher, darunter %s",
                "%d Gegner stellten sich mir entgegen, darunter %s",
            },
            tails = {
                ", Teil der mühsam errungenen Fortschritte des Tages.",
                "; jede Begegnung markierte einen weiteren Wegabschnitt.",
                ", ihre Namen sind aus den Kämpfen bewahrt.",
                ", eine Aufzeichnung der Gegner, die meinen Weg kreuzten.",
            },
        },
        DIARY_OPEN = {
            start = 21,
            heads = {
                "%s brach ich von „%s“ aus auf",
                "Die Wege des Tages begannen %s in „%s“",
                "%s nahm ich den Weg von „%s“ wieder auf",
                "Meine Reise schlug %s in „%s“ ihr erstes Kapitel auf",
                "Diesen aufgezeichneten Abschnitt begann ich %s bei „%s“",
            },
            tails = {
                ", die nächste Seite lag noch ungeschrieben vor mir.",
                "; was vor mir lag, musste sich erst zeigen.",
                ", ohne zu wissen, welche Augenblicke noch kommen würden.",
                ", bereit zu sehen, wohin mich der Weg führte.",
            },
        },
        DIARY_END = {
            start = 21,
            heads = {
                "%s ließ ich den Tag in „%s“ ausklingen",
                "Der letzte verzeichnete Halt lag %s in „%s“",
                "Ich hielt die Reise %s bei „%s“ an",
                "%s endete mein Weg vorerst in „%s“",
                "Für den Moment verließ ich den Weg %s in „%s“",
            },
            tails = {
                ", die nächste Meile musste bis zu einem anderen Tag warten.",
                "; die Chronik kann später an dieser Stelle weitergehen.",
                ", die Ereignisse des Tages sicher auf den Seiten bewahrt.",
                ", und ließ den Bericht dieses Tages zur Ruhe kommen.",
            },
        },
    },
}

local function installFamily(locale, family, spec)
    local index = spec.start
    for _, head in ipairs(spec.heads) do
        for _, tail in ipairs(spec.tails) do
            locale[family .. "_" .. index] = head .. tail
            index = index + 1
        end
    end
end

for family, spec in pairs(banks[language]) do
    installFamily(L, family, spec)
end

local function installList(locale, prefix, start, values)
    for offset, value in ipairs(values) do
        locale[prefix .. "_" .. (start + offset - 1)] = value
    end
end

local extras = {
    enUS = {
        DIARY_DAY_ADVENTURE = {
            "The road had its share of hard moments.", "Some encounters asked more than I expected.",
            "Not every mile passed without a struggle.", "The day tested me in more than one way.",
            "A few turns of the road demanded my full attention.", "There were moments when persistence mattered most.",
            "The path grew difficult before it grew quiet again.", "I had to earn some of the ground I covered.",
            "A measure of danger followed me through the day.", "The journey did not spare me every hardship.",
            "Some passages were won one difficult moment at a time.", "The day's account includes its share of trials.",
        },
        DIARY_DAY_QUIETER = {
            "Between those moments, the road grew calm again.", "The day left room for small, quieter things.",
            "There was more to the journey than its trials.", "I found a little time to breathe between events.",
            "Not every part of the day called for haste.", "Some stretches passed in a gentler rhythm.",
            "The road offered a pause before it asked for more.", "I had time for ordinary moments along the way.",
            "A quieter stretch softened the day's harder edges.", "The journey also held space for simple needs.",
            "For a while, the world let me travel without urgency.", "Calmer moments found their place in the day, too.",
        },
    },
    deDE = {
        DIARY_DAY_ADVENTURE = {
            "Der Weg hielt auch schwierige Momente bereit.", "Manche Begegnung verlangte mehr, als ich erwartet hatte.",
            "Nicht jede Meile verging ohne Mühe.", "Der Tag stellte mich auf mehr als eine Weise auf die Probe.",
            "Einige Wendungen des Weges verlangten meine ganze Aufmerksamkeit.", "Manchmal zählte vor allem, nicht aufzugeben.",
            "Der Pfad wurde erst schwieriger, dann wieder ruhiger.", "Einen Teil des Weges musste ich mir verdienen.",
            "Ein wenig Gefahr begleitete mich durch den Tag.", "Die Reise ersparte mir nicht jede Mühsal.",
            "Manche Strecke gewann ich Schritt für schwierigen Schritt.", "Auch Prüfungen gehören zum Bericht dieses Tages.",
        },
        DIARY_DAY_QUIETER = {
            "Dazwischen wurde der Weg wieder ruhiger.", "Der Tag ließ Raum für kleine, stille Dinge.",
            "Die Reise bestand aus mehr als ihren Prüfungen.", "Zwischen den Ereignissen fand ich kurz Zeit zum Durchatmen.",
            "Nicht jeder Teil des Tages verlangte Eile.", "Manche Wegstücke verliefen in einem ruhigeren Takt.",
            "Der Weg gönnte mir eine Pause, bevor er mehr verlangte.", "Unterwegs blieb Zeit für die gewöhnlichen Dinge.",
            "Ein stillerer Abschnitt nahm den härteren Momenten ihre Schärfe.", "Auch einfache Bedürfnisse fanden Platz auf der Reise.",
            "Eine Weile konnte ich ohne Eile durch die Welt ziehen.", "Auch ruhigere Augenblicke fanden ihren Platz im Tag.",
        },
    },
}

installList(L, "DIARY_DAY_ADVENTURE", 13, extras[language].DIARY_DAY_ADVENTURE)
installList(L, "DIARY_DAY_QUIETER", 13, extras[language].DIARY_DAY_QUIETER)

local periodSummaries = {
    enUS = {
        MONTHS = {
            "This month left more than a list of places; these are the moments that stayed with me:",
            "I turn back through the month's pages and find these scenes waiting:",
            "Some moments from this month still rise clearly above the passing days:",
            "The month's road is long in memory; these are the parts I return to:",
            "When I look back on this month, a few moments call to me first:",
            "These pages hold the moments that gave this month its shape:",
            "The month has passed into memory, but these scenes remain near:",
            "I remember this month by the moments that changed its course:",
            "Across these weeks, certain events became landmarks in my memory:",
            "The chronicle gathers the month's most telling moments here:",
            "These are the scenes I would carry with me from this month:",
            "As I turn the page on this month, these memories come forward:",
        },
        YEARS = {
            "A year is too wide for every mile to fit on one page; these moments remain:",
            "I look back across the year and see these landmarks along the road:",
            "The year's many days have passed; these are the memories that endured:",
            "These moments give shape to the year I traveled through Azeroth:",
            "When I turn back through the year's pages, these scenes still shine through:",
            "This year left a long trail; these are the moments I would follow again:",
            "The chronicle cannot hold every step, but it keeps these turning points:",
            "Across the year, these events became part of the story I tell myself:",
            "I remember the year not as a tally, but through moments like these:",
            "The year's record gathers here the scenes that mattered most to my journey:",
            "These are the memories that still have a voice after a year on the road:",
            "As one year closes in memory, these moments remain within reach:",
        },
    },
    deDE = {
        MONTHS = {
            "Dieser Monat hinterließ mehr als Ortsnamen; diese Augenblicke blieben mir:",
            "Wenn ich die Seiten dieses Monats durchblättere, finde ich diese Szenen wieder:",
            "Einige Momente dieses Monats heben sich noch immer aus den Tagen hervor:",
            "Der Weg dieses Monats ist lang in meiner Erinnerung; zu diesen Stellen kehre ich zurück:",
            "Wenn ich auf diesen Monat blicke, melden sich zuerst einige Augenblicke:",
            "Diese Seiten bewahren, was dem Monat seine Gestalt gab:",
            "Der Monat ist Erinnerung geworden, doch diese Szenen sind mir noch nah:",
            "An die Wendepunkte erinnere ich mich, wenn ich an diesen Monat denke:",
            "In diesen Wochen wurden einige Ereignisse zu Wegmarken meiner Erinnerung:",
            "Die Chronik versammelt hier die sprechendsten Momente des Monats:",
            "Diese Szenen würde ich aus diesem Monat mit auf den Weg nehmen:",
            "Beim Umblättern dieses Monats treten diese Erinnerungen hervor:",
        },
        YEARS = {
            "Ein Jahr ist zu weit, um jede Meile auf eine Seite zu bringen; diese Momente bleiben:",
            "Wenn ich auf das Jahr zurückblicke, sehe ich diese Wegmarken vor mir:",
            "Die vielen Tage des Jahres sind vergangen; diese Erinnerungen sind geblieben:",
            "Diese Augenblicke geben dem Jahr meiner Reisen durch Azeroth seine Gestalt:",
            "Beim Durchblättern der Seiten dieses Jahres treten diese Szenen noch immer hervor:",
            "Das Jahr hinterließ eine lange Spur; diesen Momenten würde ich erneut folgen:",
            "Die Chronik kann nicht jeden Schritt bewahren, aber diese Wendepunkte schon:",
            "Im Lauf des Jahres wurden diese Ereignisse Teil meiner eigenen Geschichte:",
            "Ich erinnere mich an das Jahr nicht als Zahl, sondern durch solche Augenblicke:",
            "Der Jahresbericht versammelt hier die Szenen, die meinen Weg geprägt haben:",
            "Diese Erinnerungen haben auch nach einem Jahr auf Reisen noch eine Stimme:",
            "Am Ende eines Jahres bleiben diese Momente in meiner Erinnerung greifbar:",
        },
    },
}

installList(L, "DIARY_PERIOD_SUMMARY_MONTHS", 13, periodSummaries[language].MONTHS)
installList(L, "DIARY_PERIOD_SUMMARY_YEARS", 13, periodSummaries[language].YEARS)

local periodOpen = {
    enUS = {
        Weeks = {
            "The week opened in “%s”; its final recorded road reached “%s”.",
            "My first entry of the week places me in “%s”, the last in “%s”.",
            "From “%s” I began the week's travels, and “%s” was the last recorded stop.",
            "At the week's beginning I was in “%s”; by its final page I had reached “%s”.",
            "The record follows me from “%s” at the week's start to “%s” at its close.",
            "I began this week near “%s” and left its last recorded trail in “%s”.",
            "“%s” marks the week's opening; “%s” marks its final recorded halt.",
            "The week's story starts around “%s” and ends, in the record, at “%s”.",
            "My travels began in “%s”; the week's last known page brings me to “%s”.",
            "I entered the week in “%s” and made “%s” my final recorded stop.",
            "The first scene of the week was “%s”; the last one remembered was “%s”.",
            "Between “%s” and “%s”, another week of my journey took shape.",
        },
        Months = {
            "The month began in “%s”; its last recorded road brought me to “%s”.",
            "I opened the month's account near “%s” and closed it in “%s”.",
            "From “%s” the month's travels began; “%s” was my final recorded stop.",
            "The first page finds me in “%s”; the month's last page finds me in “%s”.",
            "I started the month around “%s” and left its final trace in “%s”.",
            "“%s” marked the month's beginning, while “%s” became its last remembered place.",
            "My month on the road opened at “%s” and, in the record, ended at “%s”.",
            "The chronicle follows this month's path from “%s” to “%s”.",
            "The month's first known scene was “%s”; its last was “%s”.",
            "I set out from “%s” as the month began and reached “%s” by its end.",
            "“%s” stands at the start of the month; “%s” stands at its close.",
            "This month's recorded journey stretches from “%s” to “%s”.",
        },
        Years = {
            "The year opened in “%s”; its final recorded road reached “%s”.",
            "My first page of the year places me in “%s”, the last in “%s”.",
            "From “%s” began a year of travel that ended, in the record, at “%s”.",
            "The year's opening scene was “%s”; its last remembered place was “%s”.",
            "I began the year near “%s” and left its final recorded trace in “%s”.",
            "“%s” marks the year's first page, and “%s” its last recorded halt.",
            "The chronicle follows the year's road from “%s” to “%s”.",
            "I started this year in “%s” and reached “%s” by its final recorded entry.",
            "The year's first known scene was “%s”; its final one was “%s”.",
            "Across the year, the record carries me from “%s” to “%s”.",
            "The journey began around “%s” and its last page found me in “%s”.",
            "Between “%s” and “%s”, a year of my story unfolded.",
        },
    },
    deDE = {
        Weeks = {
            "Die Woche begann in „%s“; ihr letzter verzeichneter Weg führte nach „%s“.",
            "Mein erster Eintrag der Woche nennt „%s“, der letzte „%s“.",
            "Von „%s“ aus begann ich meine Wege der Woche; der letzte Halt lag in „%s“.",
            "Zu Wochenbeginn war ich in „%s“; auf der letzten Seite erreichte ich „%s“.",
            "Die Aufzeichnungen führen mich vom Wochenanfang in „%s“ bis nach „%s“.",
            "Ich begann die Woche nahe „%s“ und hinterließ ihre letzte Spur in „%s“.",
            "„%s“ markiert den Anfang der Woche, „%s“ ihren letzten verzeichneten Halt.",
            "Die Geschichte der Woche beginnt nahe „%s“ und endet laut Chronik in „%s“.",
            "Meine Reisen begannen in „%s“; die letzte bekannte Seite führt nach „%s“.",
            "Ich begann die Woche in „%s“ und machte „%s“ zu meinem letzten verzeichneten Halt.",
            "Die erste Szene der Woche spielte in „%s“, die letzte erinnerte sich an „%s“.",
            "Zwischen „%s“ und „%s“ nahm eine weitere Woche meiner Reise Gestalt an.",
        },
        Months = {
            "Der Monat begann in „%s“; sein letzter verzeichneter Weg führte nach „%s“.",
            "Ich eröffnete den Monatsbericht nahe „%s“ und schloss ihn in „%s“.",
            "Von „%s“ aus begannen die Reisen des Monats; mein letzter Halt lag in „%s“.",
            "Die erste Seite zeigt mich in „%s“, die letzte in „%s“.",
            "Ich begann den Monat nahe „%s“ und hinterließ seine letzte Spur in „%s“.",
            "„%s“ stand am Anfang des Monats, „%s“ wurde sein letzter erinnerter Ort.",
            "Mein Monat auf Reisen begann in „%s“ und endete laut Chronik in „%s“.",
            "Die Chronik folgt dem Weg dieses Monats von „%s“ nach „%s“.",
            "Die erste bekannte Szene des Monats spielte in „%s“, die letzte in „%s“.",
            "Als der Monat begann, brach ich in „%s“ auf; am Ende erreichte ich „%s“.",
            "„%s“ steht am Anfang des Monats, „%s“ an seinem Ende.",
            "Die aufgezeichnete Reise dieses Monats spannt sich von „%s“ bis „%s“.",
        },
        Years = {
            "Das Jahr begann in „%s“; sein letzter verzeichneter Weg führte nach „%s“.",
            "Meine erste Seite des Jahres nennt „%s“, die letzte „%s“.",
            "In „%s“ begann ein Jahr voller Wege, das laut Chronik in „%s“ endete.",
            "Die erste Szene des Jahres spielte in „%s“, sein letzter erinnerter Ort war „%s“.",
            "Ich begann das Jahr nahe „%s“ und hinterließ seine letzte verzeichnete Spur in „%s“.",
            "„%s“ markiert die erste Seite des Jahres, „%s“ seinen letzten bekannten Halt.",
            "Die Chronik folgt dem Jahresweg von „%s“ bis nach „%s“.",
            "Ich begann dieses Jahr in „%s“ und erreichte „%s“ mit dem letzten verzeichneten Eintrag.",
            "Die erste bekannte Szene des Jahres lag in „%s“, die letzte in „%s“.",
            "Im Lauf des Jahres führen mich die Aufzeichnungen von „%s“ nach „%s“.",
            "Die Reise begann nahe „%s“; auf der letzten Seite fand ich mich in „%s“ wieder.",
            "Zwischen „%s“ und „%s“ entfaltete sich ein Jahr meiner Geschichte.",
        },
    },
}

for period, values in pairs(periodOpen[language]) do
    installList(L, "DIARY_PERIOD_OPEN_" .. period, 13, values)
end

local periodWrap = {
    enUS = {
        Months = {
            "The month holds %d recorded journeys in all.", "I made %d separate journeys before the month turned.",
            "By month's end, %d journeys had found a place in my chronicle.", "The month's account closes with %d journeys remembered.",
            "I leave this month with %d journeys written on its pages.", "Across the month, I recorded %d journeys.",
            "The record of this month comes to %d journeys.", "This month, %d journeys carried me across Azeroth.",
            "The pages for the month preserve %d separate journeys.", "All told, my chronicle remembers %d journeys this month.",
            "Before the month passed, I had made %d recorded journeys.", "The month leaves behind a record of %d journeys.",
        },
        Years = {
            "The year holds %d recorded journeys in all.", "I made %d separate journeys before the year turned.",
            "By year's end, %d journeys had found a place in my chronicle.", "The year's account closes with %d journeys remembered.",
            "I leave this year with %d journeys written on its pages.", "Across the year, I recorded %d journeys.",
            "The record of this year comes to %d journeys.", "This year, %d journeys carried me across Azeroth.",
            "The pages for the year preserve %d separate journeys.", "All told, my chronicle remembers %d journeys this year.",
            "Before the year passed, I had made %d recorded journeys.", "The year leaves behind a record of %d journeys.",
        },
    },
    deDE = {
        Months = {
            "Der Monat umfasst insgesamt %d aufgezeichnete Reisen.", "Vor dem Monatswechsel unternahm ich %d einzelne Reisen.",
            "Bis zum Monatsende fanden %d Reisen Eingang in meine Chronik.", "Der Monatsbericht schließt mit %d bewahrten Reisen.",
            "Ich lasse diesen Monat mit %d Reisen auf seinen Seiten zurück.", "Im Lauf des Monats verzeichnete ich %d Reisen.",
            "Die Aufzeichnungen dieses Monats kommen auf %d Reisen.", "In diesem Monat führten mich %d Reisen durch Azeroth.",
            "Die Monatsseiten bewahren %d einzelne Reisen.", "Alles in allem erinnert sich meine Chronik an %d Reisen in diesem Monat.",
            "Bevor der Monat verging, hatte ich %d Reisen aufgezeichnet.", "Der Monat hinterlässt einen Bericht über %d Reisen.",
        },
        Years = {
            "Das Jahr umfasst insgesamt %d aufgezeichnete Reisen.", "Vor dem Jahreswechsel unternahm ich %d einzelne Reisen.",
            "Bis zum Jahresende fanden %d Reisen Eingang in meine Chronik.", "Der Jahresbericht schließt mit %d bewahrten Reisen.",
            "Ich lasse dieses Jahr mit %d Reisen auf seinen Seiten zurück.", "Im Lauf des Jahres verzeichnete ich %d Reisen.",
            "Die Aufzeichnungen dieses Jahres kommen auf %d Reisen.", "In diesem Jahr führten mich %d Reisen durch Azeroth.",
            "Die Jahresseiten bewahren %d einzelne Reisen.", "Alles in allem erinnert sich meine Chronik an %d Reisen in diesem Jahr.",
            "Bevor das Jahr verging, hatte ich %d Reisen aufgezeichnet.", "Das Jahr hinterlässt einen Bericht über %d Reisen.",
        },
    },
}

for period, values in pairs(periodWrap[language]) do
    installList(L, "DIARY_PERIOD_WRAP_" .. period, 13, values)
end

local periodEnd = {
    enUS = {
        Weeks = {
            "The week drew to a close in “%s”; I keep %s from the road across %d journeys.",
            "My final stop of the week was “%s”; I carry %s from %d recorded journeys.",
            "I left the week in “%s”, with %s gathered from %d journeys behind me.",
            "This week’s chronicle closes in “%s” and preserves %s from %d journeys.",
            "The week’s final known place was “%s”; it also remembers %s from %d journeys.",
            "“%s” became the week’s last halt, with %s kept across %d journeys.",
            "My week ended, in the record, at “%s”, with %s from %d journeys.",
            "At “%s” I set down the week, keeping %s from %d journeys.",
            "I reached “%s” before the week closed, carrying %s from %d recorded journeys.",
            "The week’s final page places me in “%s” and preserves %s from %d journeys.",
            "The week closes at “%s”, with %s kept across %d recorded journeys.",
            "My account of the week ends at “%s” with %s gathered across %d journeys.",
        },
        Months = {
            "The month came to rest in “%s”. Its pages hold %s across %d journeys.",
            "My final stop of the month was “%s”; I carry %s from %d recorded journeys.",
            "I left the month in “%s”, with %s gathered from %d journeys behind me.",
            "This month’s chronicle closes in “%s” and preserves %s from %d journeys.",
            "The month’s final known place was “%s”; it also remembers %s from %d journeys.",
            "“%s” became the month’s last halt, with %s kept across %d journeys.",
            "My month ended, in the record, at “%s”, with %s from %d journeys.",
            "At “%s” I set down the month, keeping %s from %d journeys.",
            "I reached “%s” before the month closed, carrying %s from %d recorded journeys.",
            "The month’s final page places me in “%s” and preserves %s from %d journeys.",
            "The month closes at “%s”, with %s kept across %d recorded journeys.",
            "My account of the month ends at “%s” with %s gathered across %d journeys.",
        },
        Years = {
            "The year came to rest in “%s”. Its pages hold %s across %d journeys.",
            "My final stop of the year was “%s”; I carry %s from %d recorded journeys.",
            "I left the year in “%s”, with %s gathered from %d journeys behind me.",
            "This year’s chronicle closes in “%s” and preserves %s from %d journeys.",
            "The year’s final known place was “%s”; it also remembers %s from %d journeys.",
            "“%s” became the year’s last halt, with %s kept across %d journeys.",
            "My year ended, in the record, at “%s”, with %s from %d journeys.",
            "At “%s” I set down the year, keeping %s from %d journeys.",
            "I reached “%s” before the year closed, carrying %s from %d recorded journeys.",
            "The year’s final page places me in “%s” and preserves %s from %d journeys.",
            "The year closes at “%s”, with %s kept across %d recorded journeys.",
            "My account of the year ends at “%s” with %s gathered across %d journeys.",
        },
    },
    deDE = {
        Weeks = {
            "Die Woche kam in „%s“ zur Ruhe. Ihre Seiten bewahren %s aus %d Reisen.",
            "Mein letzter Wochenhalt lag in „%s“; ich nehme %s aus %d aufgezeichneten Reisen mit.",
            "Ich beendete die Woche in „%s“; hinter mir lagen %s aus %d Reisen.",
            "Die Chronik schließt diese Woche in „%s“ und bewahrt %s aus %d Reisen.",
            "Der letzte bekannte Ort der Woche war „%s“; sie erinnert außerdem an %s aus %d Reisen.",
            "„%s“ wurde zum letzten Halt der Woche; meine Chronik bewahrt %s aus %d Reisen.",
            "Laut Aufzeichnungen endete meine Woche in „%s“; %s blieb aus %d Reisen.",
            "In „%s“ schlug ich die letzte Seite der Woche auf und bewahre %s aus %d Reisen.",
            "Bevor die Woche endete, erreichte ich „%s“ und nahm %s aus %d Reisen mit.",
            "Die letzte Seite der Woche verortet mich in „%s“ und hält %s aus %d Reisen fest.",
            "Die Woche schließt in „%s“; die Aufzeichnungen halten %s aus %d Reisen fest.",
            "Mein Wochenbericht endet in „%s“ mit %s aus insgesamt %d Reisen.",
        },
        Months = {
            "Der Monat kam in „%s“ zur Ruhe. Seine Seiten bewahren %s aus %d Reisen.",
            "Mein letzter Monatshalt lag in „%s“; ich nehme %s aus %d aufgezeichneten Reisen mit.",
            "Ich beendete den Monat in „%s“; hinter mir lagen %s aus %d Reisen.",
            "Die Chronik schließt diesen Monat in „%s“ und bewahrt %s aus %d Reisen.",
            "Der letzte bekannte Ort des Monats war „%s“; er erinnert außerdem an %s aus %d Reisen.",
            "„%s“ wurde zum letzten Halt des Monats; meine Chronik bewahrt %s aus %d Reisen.",
            "Laut Aufzeichnungen endete mein Monat in „%s“; %s blieb aus %d Reisen.",
            "In „%s“ schlug ich die letzte Seite des Monats auf und bewahre %s aus %d Reisen.",
            "Bevor der Monat endete, erreichte ich „%s“ und nahm %s aus %d Reisen mit.",
            "Die letzte Seite des Monats verortet mich in „%s“ und hält %s aus %d Reisen fest.",
            "Der Monat schließt in „%s“; die Aufzeichnungen halten %s aus %d Reisen fest.",
            "Mein Monatsbericht endet in „%s“ mit %s aus insgesamt %d Reisen.",
        },
        Years = {
            "Das Jahr kam in „%s“ zur Ruhe. Seine Seiten bewahren %s aus %d Reisen.",
            "Mein letzter Jahreshalt lag in „%s“; ich nehme %s aus %d aufgezeichneten Reisen mit.",
            "Ich beendete das Jahr in „%s“; hinter mir lagen %s aus %d Reisen.",
            "Die Chronik schließt dieses Jahr in „%s“ und bewahrt %s aus %d Reisen.",
            "Der letzte bekannte Ort des Jahres war „%s“; es erinnert außerdem an %s aus %d Reisen.",
            "„%s“ wurde zum letzten Halt des Jahres; meine Chronik bewahrt %s aus %d Reisen.",
            "Laut Aufzeichnungen endete mein Jahr in „%s“; %s blieb aus %d Reisen.",
            "In „%s“ schlug ich die letzte Seite des Jahres auf und bewahre %s aus %d Reisen.",
            "Bevor das Jahr endete, erreichte ich „%s“ und nahm %s aus %d Reisen mit.",
            "Die letzte Seite des Jahres verortet mich in „%s“ und hält %s aus %d Reisen fest.",
            "Das Jahr schließt in „%s“; die Aufzeichnungen halten %s aus %d Reisen fest.",
            "Mein Jahresbericht endet in „%s“ mit %s aus insgesamt %d Reisen.",
        },
    },
}

for period, values in pairs(periodEnd[language]) do
    installList(L, "DIARY_PERIOD_END_" .. period, 13, values)
end

local function addFactFrames(locale, one)
    local heads, tails
    if language == "deDE" then
        if one then
            heads = {
                "Unter der Rubrik „%s“ steht ein einzelner Eintrag.",
                "Ein Moment aus „%s“ hat eine eigene Zeile erhalten.",
                "Die Chronik führt unter „%s“ einen besonderen Eintrag.",
                "Zu „%s“ blieb ein einzelner Moment besonders deutlich.",
                "Ein Eintrag unter „%s“ hebt sich von den übrigen ab.",
                "Die Rubrik „%s“ bewahrt einen Augenblick für sich.",
                "Unter „%s“ findet sich eine Erinnerung aus diesem Abschnitt.",
                "Ein einzelner Vermerk unter „%s“ blieb mir im Gedächtnis.",
                "Die Aufzeichnungen nennen unter „%s“ einen besonderen Moment.",
                "Ein Ereignis der Rubrik „%s“ steht hier für sich.",
                "Unter „%s“ verdient ein Augenblick eine eigene Zeile.",
            }
            tails = {
                " Besonders in Erinnerung blieb mir: %s", " Die Chronik bewahrt dazu: %s",
                " Auf der Seite steht: %s", " Festgehalten habe ich: %s",
            }
        else
            heads = {
                "Ich verzeichnete %d Erlebnisse unter der Rubrik „%s“.",
                "Die Chronik hält %d Einträge unter „%s“ fest.",
                "Aus dieser Zeit stammen %d vermerkte Momente der Rubrik „%s“.",
                "Auf diesen Seiten stehen %d Erlebnisse unter „%s“.",
                "Ich zählte %d Einträge in der Rubrik „%s“.",
                "Der Bericht umfasst %d festgehaltene Momente unter „%s“.",
                "Während dieser Zeit sammelten sich %d Vermerke unter „%s“.",
                "Die Reise hinterließ %d Einträge der Rubrik „%s“.",
                "In der Aufzeichnung stehen %d beobachtete Ereignisse unter „%s“.",
                "Die Seiten bewahren %d Erlebnisse aus dem Bereich „%s“.",
                "Mein Bericht zählt %d Erinnerungen unter „%s“.",
            }
            tails = {
                " Besonders deutlich blieb mir: %s", " Unter ihnen ragt für mich heraus: %s",
                " Ein Beispiel, das ich wiedererkenne: %s", " Zu den bleibenden Eindrücken gehört: %s",
            }
        end
    elseif one then
        heads = {
            "Under “%s,” the chronicle keeps one entry.",
            "One moment from “%s” earned its own line.",
            "The record marks a particular entry under “%s.”",
            "One moment from “%s” remained especially clear.",
            "A single entry under “%s” stands apart from the rest.",
            "The “%s” section preserves one moment on its own.",
            "One remembered detail appears under “%s.”",
            "A single note under “%s” stayed with me.",
            "The record names one particular moment under “%s.”",
            "One event in “%s” has a page to itself.",
            "Under “%s,” one moment deserves its own line.",
        }
        tails = {
            " The detail I remember is: %s", " The chronicle preserves this: %s",
            " The page records: %s", " I chose to keep this moment: %s",
        }
    else
        heads = {
            "I recorded %d moments under “%s.”",
            "The chronicle keeps %d entries under “%s.”",
            "This stretch added %d remembered moments to “%s.”",
            "These pages hold %d events from “%s.”",
            "I counted %d entries under “%s.”",
            "The record covers %d noted moments under “%s.”",
            "During this time, %d observations entered “%s.”",
            "The journey left %d records in “%s.”",
            "My notes list %d observed events under “%s.”",
            "These pages preserve %d experiences from “%s.”",
            "My account counts %d remembered moments in “%s.”",
        }
        tails = {
            " The one that stands out is %s", " Among them, I remember %s most clearly",
            " One lasting example is %s", " A moment that stayed with me was %s",
        }
    end

    local out = {}
    for _, head in ipairs(heads) do
        for _, tail in ipairs(tails) do
            out[#out + 1] = head .. tail .. "."
        end
    end
    -- Existing families already provide direct forms 1-3 and shared frames 4-46.
    -- Add 43 frames per number mode so the combined selector grows from 46 to 89.
    for index = 1, 43 do
        locale[(one and "DIARY_PERIOD_FACT_ONE_FRAME_" or "DIARY_PERIOD_FACT_FRAME_") .. (46 + index)] = out[index]
    end
end

addFactFrames(L, false)
addFactFrames(L, true)

local dayBridges = extras[language]
-- Explicit start indices are used above for generated family matrices; simple lists start at 13.

