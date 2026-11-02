
local ids = {
    ore = { --itemtype = 5
        note = "Ore",
        200230, --Zinc Ore
        200232, --Tin Ore
        200233, --Tempered Zinc Ingot
        200234, --Iron Ore
        200235, --NULL
        200236, --Copper Ore
        200237, --NULL
        200238, --Dark Crystal
        200239, --Silver Ore
        200240, --Tempered Tin Ingot
        200241, --NULL
        200242, --Wizard-Iron Ore
        200243, --NULL
        200244, --Moon Silver Ore
        200246, --NULL
        200247, --NULL
        200248, --Tempered Iron Ingot
        200249, --Rock Crystal
        200251, --Tempered Copper Ingot
        200253, --Tempered Dark Crystal Ingot
        200255, --Tempered Silver Ingot
        200257, --Tempered Wizard-Iron Ingot
        200259, --Tempered Moon Silver Ingot
        200261, --Tempered Abyss-Mercury Ingot
        200262, --Tempered Rune Obsidian Ingot
        200263, --Arcane Zinc Ingot
        200264, --Abyss-Mercury
        200265, --Mithril
        200268, --Rune Obsidian Ore
        200269, --Mysticite
        200506, --Cyanide
        200507, --Flame Dust
        201710, --Zinc Sand
        201711, --Tin Sand
        201712, --Arcane Tin Ingot
        201713, --Iron Sand
        201714, --Copper Sand
        201715, --Dark Crystal Sand
        201716, --Silver Sand
        201717, --Wizard-Iron Sand
        201718, --Moon Silver Sand
        201719, --Arcane Iron Ingot
        201720, --Abyss-Mercury Sand
        201721, --Rune Obsidian Sand
        201722, --Arcane Copper Ingot
        201723, --Zinc Nugget
        201724, --Tin Nugget
        201725, --Iron Nugget
        201726, --Copper Nugget
        201727, --Dark Crystal Nugget
        201728, --Silver Nugget
        201729, --Wizard-Iron Nugget
        201730, --Moon Silver Nugget
        201731, --Abyss-Mercury Nugget
        201732, --Rune Obsidian Nugget
        201733, --Arcane Dark Crystal Ingot
        201734, --Arcane Silver Ingot
        201735, --Arcane Wizard-Iron Ingot
        201736, --Zinc Ingot
        201737, --Tin Ingot
        201738, --Iron Ingot
        201739, --Copper Ingot
        201740, --Dark Crystal Ingot
        201741, --Silver Ingot
        201742, --Wizard-Iron Ingot
        201743, --Moon Silver Ingot
        201744, --Abyss-Mercury Ingot
        201745, --Rune Obsidian Ingot
        201746, --Arcane Moon Silver Ingot
        201747, --Arcane Abyss-Mercury Ingot
        201748, --Arcane Rune Obsidian Ingot
        202315, --Frost Crystal
        202316, --Mica
        202561, --Flame Dust Sand
        202562, --Cyanide Sand
        202563, --Rock Crystal Sand
        202564, --Mysticite Sand
        202565, --Mithril Sand
        202566, --Frost Crystal Sand
        202567, --Mica Sand
        202568, --Flame Dust Nugget
        202569, --Cyanide Nugget
        202570, --Rock Crystal Nugget
        202571, --Mysticite Nugget
        202572, --Mithril Nugget
        202573, --Frost Crystal Nugget
        202574, --Mica Nugget
        202575, --Flame Dust Ingot
        202576, --Cyanide Ingot
        202577, --Rock Crystal Ingot
        202578, --Mysticite Ingot
        202579, --Mithril Ingot
        202580, --Frost Crystal Ingot
        202581, --Mica Ingot
        202582, --Tempered Flame Dust Ingot
        202583, --Tempered Cyanide Ingot
        202584, --Tempered Rock Crystal Ingot
        202585, --Tempered Mysticite Ingot
        202586, --Tempered Mithril Ingot
        202587, --Tempered Frost Crystal Ingot
        202588, --Tempered Mica Ingot
        202589, --Arcane Flame Dust Ingot
        202590, --Arcane Cyanide Ingot
        202591, --Arcane Rock Crystal Ingot
        202592, --Arcane Mysticite Ingot
        202593, --Arcane Mithril Ingot
        202594, --Arcane Frost Crystal Ingot
        202595, --Arcane Mica Ingot
        206263, --Star Pearl
        206592, --Moonlight Pearl
        206695, --Ore Essence
        207319, --Milky Way Pearl
        207320, --Dark Night Pearl
        207935, --Sys207935_name
        207936, --Sys207936_name
        208234, --Olivine
        208235, --Olivine Sand
        208236, --Olivine Nugget
        208237, --Olivine Ingot
        208238, --Tempered Olivine Ingot
        208239, --Arcane Olivine Ingot
        240314, --Purple Agate Crystal
        240315, --Purple Agate Crystal Sand
        240316, --Purple Agate Crystal Nugget
        240317, --Purple Agate Crystal Ingot
        240318, --Tempered Purple Agate Crystal Ingot
        240319, --Arcane Purple Agate Crystal Ingot
        241432, --Olegan Stone
        241433, --Olegan Stone Sand
        241434, --Olegan Stone Nugget
        241435, --Olegan Stone Ingot
        241436, --Tempered Olegan Stone Ingot
        241437, --Arcane Olegan Stone Ingot
        241438, --Rein Crystal
        241439, --Rein Crystal Sand
        241440, --Rein Crystal Nugget
        241441, --Rein Crystal Ingot
        241442, --Tempered Rein Crystal Ingot
        241443, --Arcane Rein Crystal Ingot
        242159, --NULL
        242246, --Silver Star Stone
        242247, --Silver Star Stone Sand
        242248, --Silver Star Stone Nugget
        242249, --Silver Star Stone Ingot
        242258, --Dust of Mutation
        242259, --Mutation Dust Sand
        242260, --Mutation Dust Nugget
        242261, --Mutation Dust Ingot
        242270, --Rainbow Stone
        242271, --Rainbow Stone Sand
        242272, --Rainbow Stone Nugget
        242273, --Rainbow Stone Ingot
        242282, --Argyrite
        242283, --Argyrite Sand
        242284, --Argyrite Nugget
        242285, --Argyrite Ingot
        242294, --Ironaxe Stone
        242295, --Ironaxe Stone Sand
        242296, --Ironaxe Stone Nugget
        242297, --Ironaxe Stone Ingot
        242306, --Sea Crystal
        242307, --Sea Crystal Sand
        242308, --Sea Crystal Nugget
        242309, --Sea Crystal Ingot
    },
    wood = { --itemtype = 6
        note = "Wood",
        200293, --Ash Wood
        200294, --Refined Ash Plank
        200295, --Willow Wood
        200297, --Maple Wood
        200298, --Holly Wood
        200300, --Oak Wood
        200301, --Refined Willow Plank
        200303, --Refined Maple Plank
        200304, --Pine Wood
        200305, --Refined Oak Plank
        200306, --Yew Wood
        200307, --Tarslin Demon Wood
        200308, --Refined Pine Plank
        200309, --Refined Holly Plank
        200310, --Dragonlair Wood
        200312, --Ancient Spirit Oak Wood
        200314, --Refined Yew Plank
        200315, --Refined Tarslin Demon Wood Plank
        200317, --Refined Dragonlair Wood Plank
        200319, --Refined Ancient Spirit Oak Plank
        200321, --Exquisite Ash Plank
        200323, --Exquisite Willow Plank
        200324, --Exquisite Maple Plank
        200325, --Exquisite Oak Plank
        200326, --Redwood
        200327, --Exquisite Pine Plank
        200328, --Exquisite Holly Plank
        200330, --Exquisite Yew Plank
        200331, --Sagewood
        200332, --Dragon Beard Root Wood
        200508, --Chime Wood
        200509, --Stone Rotan Wood
        201749, --Ash Timber
        201750, --Willow Timber
        201751, --Maple Timber
        201752, --Oak Timber
        201753, --Holly Timber
        201754, --Pine Timber
        201755, --Exquisite Tarslin Demon Wood Plank
        201756, --Exquisite Dragonlair Wood Plank
        201757, --Yew Timber
        201758, --Tarslin Demon Wood Timber
        201759, --Dragonlair Wood Timber
        201760, --Ancient Spirit Oak Timber
        201761, --Ash Lumber
        201762, --Willow Lumber
        201763, --Maple Lumber
        201764, --Oak Lumber
        201765, --Pine Lumber
        201766, --Holly Lumber
        201767, --Yew Lumber
        201768, --Tarslin Demon Wood Lumber
        201769, --Dragonlair Wood Lumber
        201770, --Ancient Spirit Oak Lumber
        201771, --Exquisite Ancient Spirit Oak Wood Plank
        201773, --Ash Plank
        201774, --Willow Plank
        201775, --Maple Plank
        201776, --Oak Plank
        201777, --Pine Plank
        201778, --Holly Plank
        201779, --Yew Plank
        201780, --Tarslin Demon Wood Plank
        201781, --Dragonlair Wood Plank
        201782, --Ancient Spirit Oak Plank
        202317, --Fairywood
        202318, --Aeontree Wood
        202597, --Stone Rotan Timber
        202598, --Redwood Timber
        202599, --Dragon Beard Root Timber
        202600, --Sagewood Timber
        202601, --Fairywood Timber
        202602, --Aeontree Timber
        202603, --Chime Wood Lumber
        202604, --Stone Rotan Lumber
        202605, --Redwood Lumber
        202606, --Dragon Beard Root Lumber
        202607, --Sagewood Lumber
        202608, --Fairywood Lumber
        202609, --Aeontree Lumber
        202610, --Chime Wood Plank
        202611, --Stone Rotan Plank
        202612, --Redwood Plank
        202613, --Dragon Beard Root Plank
        202614, --Sagewood Plank
        202615, --Fairywood Plank
        202616, --Aeontree Plank
        202617, --Refined Chime Wood Plank
        202618, --Refined Stone Rotan Plank
        202619, --Refined Redwood Plank
        202620, --Refined Dragon Beard Root Plank
        202621, --Refined Sagewood Plank
        202622, --Refined Fairywood Plank
        202623, --Refined Aeontree Plank
        202624, --Exquisite Chime Wood Plank
        202625, --Exquisite Stone Rotan Plank
        202626, --Exquisite Redwood Plank
        202627, --Exquisite Dragon Beard Root Plank
        202628, --Exquisite Sagewood Plank
        202629, --Exquisite Fairywood Plank
        202630, --Exquisite Aeontree Plank
        206262, --Golden Ear of Grain
        206591, --Sunset Ear of Grain
        206696, --Wood Essence
        207321, --Finished Wood Chest
        207322, --Exquisite Wooden Chest
        207937, --Sys207937_name
        207938, --Sys207938_name
        208240, --Fastan Banyan
        208241, --Fastan Banyan Timber
        208242, --Fastan Banyan Lumber
        208243, --Fastan Banyan Plank
        208244, --Refined Fastan Banyan Plank
        208245, --Exquisite Fastan Banyan Plank
        240323, --Janost Cypress Wood
        240324, --Janost Cypress Timber
        240325, --Janost Cypress Lumber
        240326, --Janost Cypress Plank
        240327, --Refined Janost Cypress Plank
        240328, --Exquisite Janost Cypress Plank
        241420, --Todo Ginkgo Tree
        241421, --Todo Ginkgo Timber
        241422, --Todo Ginkgo Lumber
        241423, --Todo Ginkgo Plank
        241424, --Refined Todo Ginkgo Plank
        241425, --Exquisite Todo Ginkgo Plank
        241426, --Stone Pine
        241427, --Stone Pine Timber
        241428, --Stone Pine Lumber
        241429, --Stone Pine Plank
        241430, --Refined Stone Pine Plank
        241431, --Exquisite Stone Pine Plank
        242242, --Nadal Wisteria Wood
        242243, --Nadal Wisteria Timber
        242244, --Nadal Wisteria Lumber
        242245, --Nadal Wisteria Plank
        242254, --Summer Oak
        242255, --Summer Oak Wood
        242256, --Summer Oak Lumber
        242257, --Summer Oak Plank
        242266, --Fire Mountain Tree
        242267, --Fire Mountain Tree Timber
        242268, --Fire Mountain Tree Lumber
        242269, --Fire Mountain Tree Plank
        242278, --Kandi Tree
        242279, --Kandi Tree Timber
        242280, --Kandi Tree Lumber
        242281, --Kandi Tree Plank
        242290, --Blood Palm Wood
        242291, --Blood Palm Timber
        242292, --Blood Palm Lumber
        242293, --Blood Palm Plank
        242302, --Bleak Fir
        242303, --Bleak Fir Timber
        242304, --Bleak Fir Lumber
        242305, --Bleak Fir Plank    
    },
    herb = { --itemtype = 7
        note = "Herb",
        200333, --Bitterleaf
        200334, --Beetroot
        200335, --Mountain Demon Grass
        200336, --Pure Mountain Demon Grass Extract
        200337, --Pure Beetroot Extract
        200338, --Moxa
        200339, --Pure Bitterleaf Extract
        200340, --Pure Moxa Extract
        200341, --Pure Dusk Orchid Extract
        200342, --Barsaleaf
        200343, --Dusk Orchid
        200344, --Pure Barsaleaf Extract
        200345, --Moon Orchid
        200346, --Sinners Palm
        200347, --NULL
        200349, --Dragon Mallow
        200350, --Thorn Apple
        200351, --NULL
        200352, --NULL
        200355, --Pure Moon Orchid Extract
        200356, --Pure Sinners Palm Extract
        200360, --Pure Dragon Mallow Extract
        200364, --Pure Thorn Apple Extract
        200366, --Mountain Demon Grass Essence
        200367, --Beetroot Essence
        200368, --Bitterleaf Essence
        201785, --Mountain Demon Grass Bundle
        201786, --Beetroot Bundle
        201787, --Moxa Essence
        201788, --Moxa Bundle
        201789, --Bitterleaf Bundle
        201790, --Dusk Orchid Essence
        201791, --Dusk Orchid Bundle
        201792, --Barsaleaf Bundle
        201793, --Barsaleaf Essence
        201794, --Moon Orchid Bundle
        201795, --Moon Orchid Essence
        201796, --Sinners Palm Bundle
        201797, --Dragon Mallow Bundle
        201798, --Thorn Apple Bundle
        201799, --Mountain Demon Grass Sap
        201800, --Beetroot Sap
        201801, --Bitterleaf Sap
        201802, --Moxa Sap
        201803, --Dusk Orchid Sap
        201804, --Barsaleaf Sap
        201805, --Moon Orchid Sap
        201806, --Sinners Palm Sap
        201807, --Dragon Mallow Sap
        201808, --Thorn Apple Juice
        201809, --Sinners Palm Essence
        201810, --Dragon Mallow Essence
        201811, --Thorn Apple Essence
        201813, --Mountain Demon Grass Extract
        201814, --Beetroot Extract
        201815, --Bitterleaf Extract
        201816, --Moxa Extract
        201817, --Dusk Orchid Extract
        201818, --Barsaleaf Extract
        201819, --Moon Orchid Extract
        201820, --Sinners Palm Extract
        201821, --Dragon Mallow Extract
        201822, --Thorn Apple Extract
        202552, --Rosemary
        202553, --Bison Grass
        202554, --Foloin Nut
        202555, --Green Thistle
        202556, --Straw Mushroom
        202557, --Mirror Sedge
        202558, --Goblin Grass
        202596, --Chime Wood Timber
        202631, --Rosemary Bundle
        202632, --Bison Grass Bundle
        202633, --Foloin Nut Butter
        202634, --Green Thistle Bundle
        202635, --Straw Mushroom Bundle
        202636, --Mirror Sedge Bundle
        202637, --Goblin Grass Bundle
        202638, --Rosemary Sap
        202639, --Bison Grass Sap
        202640, --Foloin Nut Sap
        202641, --Green Thistle Sap
        202642, --Straw Mushroom Sap
        202643, --Mirror Sedge Sap
        202644, --Goblin Grass Sap
        202645, --Rosemary Extract
        202646, --Bison Grass Extract
        202647, --Foloin Nut Extract
        202648, --Green Thistle Extract
        202649, --Straw Mushroom Extract
        202650, --Mirror Sedge Extract
        202651, --Goblin Grass Extract
        202652, --Pure Rosemary Extract
        202653, --Pure Bison Grass Extract
        202654, --Pure Foloin Nut Extract
        202655, --Pure Green Thistle Extract
        202656, --Pure Straw Mushroom Extract
        202657, --Pure Mirror Sedge Extract
        202658, --Pure Goblin Grass Extract
        202659, --Rosemary Essence
        202660, --Bison Grass Essence
        202661, --Foloin Nut Essence
        202662, --Green Thistle Essence
        202663, --Straw Mushroom Essence
        202664, --Mirror Sedge Essence
        202665, --Goblin Grass Essence
        206261, --Fortune Grass
        206590, --Magic Fortune Grass
        206697, --Herb Essence
        207323, --Morning Dew
        207324, --Moonlight Pearl
        207939, --Sys207939_name
        207940, --Sys207940_name
        208246, --Verbena
        208247, --Bouquet of Verbena
        208248, --Verbena Juice
        208249, --Verbena Extract
        208250, --Pure Verbena Extract
        208251, --Verbena Essence
        208306, --NULL
        240329, --Nocturnal Lantern Grass
        240330, --Nocturnal Lantern Grass Bundle
        240331, --Nocturnal Lantern Grass Sap
        240332, --Nocturnal Lantern Grass Extract
        240333, --Pure Nocturnal Lantern Grass Extract
        240334, --Nocturnal Lantern Grass Essence
        241408, --Thunderhoof Grass
        241409, --Thunderhoof Grass Bundle
        241410, --Thunderhoof Grass Sap
        241411, --Thunderhoof Grass Extract
        241412, --Pure Thunderhoof Grass Extract
        241413, --Thunderhoof Grass Essence
        241414, --Dovetail Flower
        241415, --Dovetail Flower Bouquet
        241416, --Dovetail Flower Sap
        241417, --Dovetail Flower Extract
        241418, --Pure Dovetail Flower Extract
        241419, --Dovetail Flower Essence
        242250, --Isyeh Grass
        242251, --Isyeh Grass Bundle
        242252, --Isyeh Grass Sap
        242253, --Isyeh Grass Extract
        242262, --Cold Psilotum
        242263, --Cold Psilotum Bundle
        242264, --Cold Psilotum Juice
        242265, --Cold Psilotum Extract
        242274, --Snow Grass
        242275, --Snow Grass Bundle
        242276, --Snow Grass Juice
        242277, --Snow Grass Extract
        242286, --Shell Flower
        242287, --Shell Flower Bundle
        242288, --Shell Flower Juice
        242289, --Shell Flower Extract
        242298, --Dragonsprout Grass
        242299, --Dragonsprout Grass Bundle
        242300, --Dragonsprout Grass Sap
        242301, --Dragonsprout Grass Extract
        242310, --Moon Grass
        242311, --Moon Grass Bundle
        242312, --Moon Grass Juice
        242313, --Moon Grass Extract
    },
    FusionStone = { -- itemtype = 30
        note = "Fusion Stones",
        201366, --Purified Fusion Stone
        202880, --Fusion Stone
        202881, --Purified Fusion Stone
        202882, --Fusion Stone
        202883, --Fusion Stone
        202884, --NULL
        202885, --Fusion Stone
        202995, --Fusion Stone
        202996, --Fusion Stone
        202997, --Fusion Stone
        202998, --Fusion Stone
        202999, --Random Fusion Stone
        203000, --Fusion Stone
        203001, --Fusion Stone
        203002, --Fusion Stone
        203003, --Fusion Stone
        203004, --Fusion Stone
        206219, --Fusion Stone
        206220, --Fusion Stone
        206227, --Fusion Stone
        206694, --Honor Fusion Stone
        207004, --Fusion Stone
        208302, --Purified Fusion Stone
        208938, --Enchanted Fusion Stone
        208939, --Enchanted Fusion Stone
        208940, --Enchanted Fusion Stone
        208941, --Enchanted Fusion Stone
        208942, --Enchanted Fusion Stone
        208943, --Enchanted Fusion Stone
        208944, --Enchanted Fusion Stone
        208947, --Worn Fusion Stone
        208948, --Worn Fusion Stone
        208949, --Worn Fusion Stone
        208950, --Worn Fusion Stone
        208951, --Worn Fusion Stone
        209381, --ME - Sys209381_name
        209382, --ME - Sys209382_name
        209383, --ME - Sys209383_name
        244863, --Sys244863_name
    },
    BagStats = {
        note = "Bag Stats",
        224451, --Kette von Chassizz - 100 --Beutel
        227161, --Ring von Chassizz - 100 --Beutel
        229868, --Ohrringe von Chassizz - 100 --Beutel
    },
    GuildRes = {
        note = "Guild Ressources",
        202916, --Guild Rune
        207325, --Dread Essence
        207326, --Nightmare Essence

        202917, --Guild Stone
        207329, --Dauntless Core
        207330, --Wisdom Core

        203450, --Ruby
        207929, --Handcrafted Ruby
        207930, --Teardrop Ruby

        206697, --Herb Essence
        206261, --Fortune Grass
        206590, --Magic Fortune Grass

        206696, --Wood Essence
        206262, --Golden Ear of Grain
        206591, --Sunset Ear of Grain

        206695, --Ore Essence
        206263, --Star Pearl
        206592, --Moonlight Pearl
    },
    Food = {
        note = "Bufffood",
        200083, --Gebratener Fisch
        200084, --Gebratenes Fleisch
        200085, --Gebratener salziger Fisch
        200086, --Gebratenes Fleisch mit Knoblauch
        200089, --Gesalzener Fisch
        200090, --Geräucherter Speck
        200091, --Gesalzener Fisch mit Soße
        200092, --Geräucherter Speck mit Kräutern
        200095, --Gebratenes Hähnchen mit Honig
        200096, --Fischei-Sandwich
        200097, --Knusprig gebratenes Hähnchen mit Honig
        200098, --Kaviar-Sandwich
        200101, --Cremige Meeresfrüchte-Pastete
        200102, --Burrito mit Fleischsoße
        200103, --Ausgezeichnete Meeresfrüchte
        200104, --Burrito mit scharfer Fleischsoße
        200107, --Sumpf-Allerlei
        200108, --Seewurmsalat
        200109, --Köstliches Sumpf-Allerlei
        200110, --Unvorstellbarer Salat
        200113, --Dreifarbige Wurst des Generals
        200114, --Fischfrikadelle mit Käse
        200115, --Motis gemischte Wurst
        200116, --Kaiserliche Meeresfrüchte-Pastete
        200119, --Mahl des Drachens
        200120, --Rituelle Eucharistie
        200121, --Mahl des Schicksals
        200122, --Abendessen der Götter
        200359, --Heißer Eintopf
        200665, --NULL
        200678, --NULL
        200809, --NULL
        200810, --NULL
        200813, --NULL
        200814, --NULL
        200817, --NULL
        200818, --NULL
        200821, --NULL
        200917, --NULL
        201036, --NULL
        201037, --NULL
        201038, --NULL
        201039, --NULL
        201040, --NULL
        201532, --Überraschende Brühe
        201533, --Winziger magischer Keks
        202239, --Reisklöße mit roten Bohnen
        202240, --Reisklöße mit Ei
        202241, --Realgarwein
        202242, --Reifer Realgarwein
        203123, --NULL
        203124, --NULL
        203125, --NULL
        203126, --NULL
        203127, --Kürbispastete der Gewandtheit
        203128, --NULL
        203129, --NULL
        203130, --NULL
        203131, --NULL
        203159, --Kürbispizza
        203160, --Kürbissuppe des Glücks
        203794, --Gerösteter Speck
        203795, --Saftigsüß gebratener Flügel
        203796, --Gebackene Meeresfrüchte-Pastete
        203797, --Zyklopen-Burrito
        203798, --Flammen-Sandwich
        203799, --Köstlicher Meeresfrüchte-Salat
        203800, --Extravagantes Sumpf-Allerlei
        203801, --Wundersalat
        203802, --Spezial Canyon-Allerlei
        203803, --Scalok-Wurst
        203856, --Weinbrand
        203859, --Wein
        203860, --Calteco
        203862, --Kirsche
        205894, --Feuerstiefelzwerg-Steinsaft
        205895, --Bretzel
        205896, --Geröstete Schweinshaxe
        205897, --Knuspriges Würstchen
        205898, --Feuerwerkssaft
        205899, --Friersaft
        206248, --Frischer Straußenschmaus
        206259, --Spaghetti mit Hackfleischsoße
        206260, --Handgepflückte Moosbeere
        206735, --Köstliche Reiskuchensuppe
        206800, --Spezial-Käsesuppe
        207060, --Nudeln aus Sojabohnenpaste
        207061, --Heiße Nudelsuppe
        207062, --Essiggurke
        207209, --Besonderer gesalzener Fisch des Hausmädchens mit Soße
        207210, --Besonderer geräucherter Speck des Hausmädchens mit Kräutern
        207211, --Besonderes Kaviar-Sandwich des Hausmädchens
        207212, --Besondere Meeresfrüchteauswahl des Hausmädchens
        207213, --Besonderes scharfes Burrito des Hausmädchens mit Fleischsoße
        207214, --Besondere Sumpf-Speise des Hausmädchens
        207215, --Besonderer unglaublicher Salat des Hausmädchens
        207216, --Besondere Fischfrikadelle mit Käse des Hausmädchens
        207604, --Geschwärztes Fischfilet
        207605, --Gewürzter Grillfisch
        207606, --Grillfisch
        207607, --Räucherfisch
        207608, --Gebratener Salzfisch
        207609, --Saftiger Backfisch
        207610, --Fischfilet mit Pfeffer
        207611, --Pfannengebratenes Fischsteak
        207612, --Gedünstetes Fischsteak
        207635, --Laib magisches Hartbrot
        207636, --Laib hausgemachtes Schwarzbrot
        207637, --Luftig leichtes Brot
        207638, --Knuspriger Toast
        207639, --Knoblauchbrot
        207640, --Sesambrot
        207641, --Teigröllchen mit Zimt
        207642, --Naturbrot
        207643, --Brot mit Pygmierum-Aroma
        207644, --Salatsandwich
        207645, --Fleischsandwich
        207646, --Spiegeleisandwich
        207647, --Riesiges Sandwich
        207648, --Beerensandwich
        207649, --Schinken-Sandwich
        207650, --Pökelfleisch-Sandwich
        207651, --Räucherhähnchen-Sandwich
        207652, --Gemüse-Sandwich
        207653, --Geschwärztes Rippchen
        207654, --Gewürzte Rippchen
        207655, --Gegrillte Rippchen
        207656, --Geräucherte Rippchen
        207657, --Gebratene Rippchen
        207658, --Saftiges Rippchen
        207659, --Pfeffer-Rippchen
        207660, --Gebratene Rippchen
        207661, --Rippchen mit Honig
        208175, --Zum Trocknen ausgelegte Frucht
        208209, --Eisbein in Biermarinade
        208210, --Gegrillte Leberwurst
        208211, --TW - Sys208211_name
        208212, --TW - Sys208212_name
        208915, --Üppiges Neujahrsmahl
        209135, --Blumenfest-Belohnungspastete
        209299, --Frühlingsregenfest-Regenbogen-Ei
        209535, --Bigos
        209768, --JP - Sys209768_name
        209769, --JP - Sys209769_name
        240063, --Lauffeuerelement-Fruchtstärkung
        240064, --Elfenfrucht-Mocktail
        240065, --Drachenatem
        240078, --Würziger Eissaft
        240079, --Milchiger Hochlandsaft
        240249, --Kräutersaft-Wackelpudding
        240250, --Salzbrezel
        240251, --Exquisite kalte Platte
        240276, --Räucherkäse
        240277, --Kräuterhühnchen
        240278, --Bratkartoffeln mit Sauerkraut
        240279, --Geröstetes Roggenbrot
        240365, --Gebratenes Schweinekotelett
        240366, --Schweinerippchen
        240367, --Schweinefleisch mit schwarzem Pfeffer
        240368, --Geschmortes Schweinefleisch
        240369, --Fisch mit Essig
        240370, --Pikantes Fischstäbchen
        240371, --Gelbfisch süß-sauer
        240372, --Tofu-Dorsch
        240738, --Frisch zubereitete Spaghetti mit Hackfleischsoße
        240739, --Frische handgepflückte Moosbeeren
        240981, --Blutiges Straußensteak
        240982, --Gedünstetes Straußenbrötchen
        240983, --Straußensandwich
        240984, --Geschmorter Straußenflügel
        240985, --Knuspriges Straußenmahl
        240986, --Knusprig gegrillter Straußenflügel
        240987, --Frisches Wildschweinsteak
        240988, --Pfannengerührtes Wildschweinfleisch
        240989, --Gedünstetes Wildschweinbrötchen
        240990, --Wildschweineintopf
        240991, --Geräuchertes Wildschweinfleisch
        240992, --Knusprig gegrilltes Wildschweinsteak
        242002, --Hirschsuppe
    },
    GiftFood = {
        note = "GiftFood",
        240375, --Segnungstrank
        202153, --uni pot
        201533, --Winziger magischer Keks
    },
    Seren = {
        note = "Serenstum",
        200150, --Serenstum
    },
    Laor = {
        note = "Laorwald-Obstkuchen",
        200149, --Laorwald-Obstkuchen
    },
    Dessert = {
        note = "Dessert",
        200123, --Saurer Käseball
        200124, --Kräuterfrucht
        200125, --Obst und Käse
        200126, --Aromatische Frucht
        200127, --Süße frittierte Donuts
        200128, --Brot und Marmelade
        200129, --Knusprige Donuts
        200130, --Süßes Früchtebrot
        200131, --Knoblauchbrot
        200132, --Fleisch und Brot
        200133, --Knoblauchbrot mit Kräutern
        200134, --Hervorragendes Fleisch und Brot
        200135, --Pilzpastete
        200136, --Kristallzucker
        200137, --Köstliche Pilzpastete
        200138, --Regenbogen-Kristallbonbon
        200139, --Exotische Früchtepastete
        200140, --Grüner weicher Kuchen
        200141, --Magische Früchtepastete
        200142, --Kuchen der singenden Wälder
        200143, --Teeduft-Waffel
        200144, --Kakaobuttergebäck mit Kräutern
        200145, --Exquisite Teeduft-Waffel
        200146, --Exquisites Kakaobuttergebäck
        200147, --Zaubererverpflegung
        200148, --Traumlandfrucht
        200149, --Laorwald-Obstkuchen
        200150, --Serenstum
        200776, --Gräberstadtkuchen
        200960, --NULL
        200974, --NULL
        203023, --Liebes-Schokolade
        203281, --Schokolade
        203282, --Lutscher
        203469, --Keks in Form einer Schneeflockenfest-Mütze
        203470, --Keks in Form einer Schneeflockenfest-Socke
        203520, --Schneeflockenfest-Zuckerstange
        203521, --Schneeflockenfest-Bonbon
        203522, --Schneeflockenfest-Schokoladenbonbon
        203523, --Schneeflockenfest-Toffee
        203524, --Schneeflockenfest-Lutscher
        203861, --Käsekuchen
        203863, --Schokochip
        207595, --Zartbitterschokolade
        207596, --Gewöhnliche Schokolade
        207597, --Milchschokolade
        207598, --Edle Schokolade
        207599, --Cremige Schokolade
        207600, --Handgemachte Schokolade
        207601, --Erdbeerschokolade
        207602, --Nussschokolade
        207603, --Trüffelschokolade
        207662, --Schokoladenkuchen
        207663, --Käsekuchen
        207664, --Buttercremetorte
        207665, --Honigkuchen
        207666, --Beerenkuchen
        207667, --Erdbeerkuchen mit Sahne
        207668, --Vanillekuchen
        207669, --Fruchttorte nach Art der Einheimischen
        207670, --Geburtstagskuchen
        240524, --Toffee
        240525, --Regenbogen-Lolli
        241560, --NULL
        241561, --NULL
        243911, --Jubiläum-Kirschkuchen
        243912, --Jubiläum-Obstkuchen
        243913, --Jubiläum-Erdbeertorte
    },
    Potion = {
        note = "Potion",
        200018, --Geheimnisvoller Trank
        200038, --Phirius-Spezialwässerchen - Typ A
        200151, --Einfache Medizin
        200152, --Einfacher Geist-Trank
        200154, --Einfacher Heiltrank
        200155, --Einfacher Manatrank
        200157, --NULL
        200158, --NULL
        200159, --Spruchweber-Trank
        200160, --Anregungsmittel
        200161, --NULL
        200162, --NULL
        200172, --Unsichtbarkeitstrank
        200173, --Starkes Anregungsmittel
        200174, --Salbe
        200175, --Manatrank
        200176, --Hexendoktor-Elixier
        200177, --NULL
        200178, --Heiltrank
        200179, --Manatrank
        200192, --Wasser der alten Geister
        200193, --NULL
        200194, --Lebensquelle
        200195, --Manaquelle
        200196, --Besserer Sammeltrank I
        200197, --Besserer Sammeltrank II
        200198, --Besserer Sammeltrank III
        200199, --Berührung des Einhorns
        200225, --Umarmung der Muse
        200226, --NULL
        200227, --NULL
        200228, --NULL
        200229, --Starke Medizin
        200270, --Mächtiger Geist-Trank
        200271, --Anregender Duft
        200272, --Trank der heiligen Macht
        200273, --Trank der Feuerelementar-Anziehung
        200274, --Starker Heiltrank
        200275, --Starker Manatrank
        200276, --Gereinigter anregender Duft
        200277, --Helden-Trank
        200278, --Quelle des Elements
        200279, --Trank der Windelementar-Anziehung
        200280, --Trank der Wasserelementar-Anziehung
        200281, --Trank der Erdelementar-Anziehung
        200282, --NULL
        200283, --NULL
        200286, --Schocktrank
        200418, --Sammeltrank I
        200419, --NULL
        200420, --Sammeltrank II
        200421, --NULL
        200422, --Sammeltrank III
        200423, --NULL
        200424, --Trank des Potenzials
        200425, --Elixier des Weisen
        200426, --Beruhigungspulver
        200427, --Ruhepulver
        200663, --Leichter Erste-Hilfe-Trank
        200664, --Einfacher Erste-Hilfe-Trank
        200807, --Erste-Hilfe-Trank
        200808, --Bedeutender Erste-Hilfe-Trank
        200811, --Barbarenkräuter
        200812, --Erste-Hilfe-Trank des Heilers
        200815, --Regenerationsmixtur
        200816, --Hochwirksame Regenerationsrezeptur
        200819, --Militär-Regenerationsrezeptur
        200820, --Ahnengeist-Kräuter
        201042, --Leichter magischer Trank
        201043, --Einfacher magischer Trank
        201046, --Magischer Trank
        201047, --Bedeutender magischer Trank
        201052, --Elementarmanastein
        201053, --Kondensierter magischer Trank
        201056, --Kristallmana-Medizin
        201057, --Hochwirksame Kristallmana-Medizin
        201060, --Aufgewertete Kristallmana-Medizin
        201061, --Elementargeiststein
        201134, --Erfahrungstrank
        201139, --Engelsseufzer
        201141, --Erlösung des Phönix
        201460, --Gruppen-Erfahrungstrank
        201544, --NULL
        201608, --Andauernder Erfahrungstrank
        201609, --Mächtiger Erfahrungstrank
        201610, --Fertigkeitstrank
        201617, --Experten-Fertigkeitstrank
        201618, --Meister-Fertigkeitstrank
        201619, --Glückstrank
        201812, --Verlangsamender Reittrank
        201892, --NULL
        201925, --Transformationstrank - Schneemannkönig
        201926, --Transformationstrank - Großer Lebkuchenmann
        202096, --NULL
        202099, --NULL
        202153, --Universaltrank
        202264, --Erfahrungstrank (1 Tag)
        202319, --Erfahrungstrank (7 Tage)
        202320, --Fertigkeitstrank (1 Tag)
        202321, --Fertigkeitstrank (7 Tage)
        202322, --Hochwirksamer Glückstrank
        202540, --Heiliger Phönix
        202669, --Reitgeschwindigkeits-Trank (7 Tage)
        202670, --Reitgeschwindigkeits-Trank (30 Tage)
        202886, --Erste-Hilfe-Trank für die Ausbildung
        202887, --Magischer Trank für die Ausbildung
        202906, --Bohnenpaste-Mondkuchen
        202907, --Kokos-Mondkuchen
        203415, --Transformationstrank - Riesenhüter
        203416, --Transformationstrank - Lebkuchenmann
        203417, --Transformationstrank - Phirius-Oheim
        203489, --Phirius-Spezialwässerchen - Typ A
        203490, --Phirius-Spezialwässerchen - Typ B
        203491, --Phirius-Spezialwässerchen - Typ C
        203492, --Phirius-Spezialwässerchen - Typ D
        203493, --Phirius-Spezialwässerchen - Typ E
        203494, --Phirius-Trank - Typ A
        203495, --Phirius-Trank - Typ B
        203496, --Phirius-Trank - Typ C
        203497, --Phirius-Trank - Typ D
        203498, --Phirius-Trank - Typ E
        203499, --Phirius-Elixier - Typ A
        203500, --Phirius-Elixier - Typ B
        203501, --Phirius-Elixier - Typ C
        203502, --Phirius-Elixier - Typ D
        203503, --Phirius-Elixier - Typ E
        203506, --Trank des Zorns
        203507, --Kampfstärke
        203508, --Energietrank
        203509, --Trank der herausragenden Fertigkeit
        203510, --Fokustrank
        203511, --Trank des konzentrierten Willens
        203574, --Hochwertiger Erfahrungstrank
        203591, --Kleiner Reitgeschwindigkeits-Trank (7 Tage)
        203592, --Kleiner Reitgeschwindigkeits-Trank (30 Tage)
        203593, --Einfacher Fertigkeitentrank
        203805, --Feuriger Trank
        203806, --Pulver des Friedens
        203807, --Spruchweber-Trank
        203808, --Durchsichtigkeits-Trank
        203809, --Geschenk des Einhorns
        203867, --NULL
        204130, --Magischer Wein
        204392, --NULL
        204553, --Universaltrank
        204889, --Götterkraut
        204890, --Elementargeiststein
        205861, --Trank der Stärke
        205862, --Wirksamer Trank der Stärke
        205863, --Trank der Intelligenz
        205864, --Wirksamer Trank der Intelligenz
        205865, --Trank der Weisheit
        205866, --Wirksamer Trank der Weisheit
        205867, --Trank der Geschicklichkeit
        205868, --Wirksamer Trank der Geschicklichkeit
        205869, --Trank der Ausdauer
        205870, --Wirksamer Trank der Ausdauer
        205956, --NULL
        205962, --Erfahrungstrank (30 Tage)
        205963, --Fertigkeitstrank (30 Tage)
        205974, --Einfacher Erfahrungstrank (30 Tage)
        205975, --Hochwirksamer Erfahrungstrank (30 Tage)
        205976, --Einfacher Fertigkeitstrank (30 Tage)
        205977, --Hochwirksamer Fertigkeitstrank (30 Tage)
        205978, --Glückstrank (30 Tage)
        206002, --Phirius-Trank-Prototyp
        206003, --Phirius-Elixier-Prototyp
        206004, --Phirius-Spezialwässerchen-Prototyp
        206623, --Reitgeschwindigkeits-Trank (1 Tag)
        206624, --Kleiner Reitgeschwindigkeits-Trank (1 Tag)
        206650, --Magischer Gemüsesaft (Stufe 1)
        206651, --Magischer Gemüsesaft (Stufe 2)
        206652, --Magischer Gemüsesaft (Stufe 3)
        206653, --Magischer Gemüsesaft (Stufe 4)
        206654, --Magischer Gemüsesaft (Stufe 5)
        206655, --Magischer Gemüsesaft (Stufe 6)
        206656, --Magischer Gemüsesaft (Stufe 7)
        206657, --Magischer Gemüsesaft (Stufe 8)
        206658, --Magischer Gemüsesaft (Stufe 9)
        206659, --Magischer Gemüsesaft (Stufe 10)
        206670, --Ehrenration (Stufe 1)
        206671, --Ehrenration (Stufe 2)
        206672, --Ehrenration (Stufe 3)
        206673, --Ehrenration (Stufe 4)
        206674, --Ehrenration (Stufe 5)
        206675, --Ehrenration (Stufe 6)
        206676, --Ehrenration (Stufe 7)
        206677, --Ehrenration (Stufe 8)
        206678, --Ehrenration (Stufe 9)
        206679, --Ehrenration (Stufe 10)
        206881, --Wuttrank
        206882, --Schutztrank
        206883, --Trank der dämonischen Mobilität
        206884, --Heiliger Trank
        206885, --Trank des Ansturms
        206886, --Trank des dämonischen Ruins
        206887, --Arkaner Trank
        206888, --Trank der Vernichtung
        206889, --Trank der Raserei
        206891, --Echsenblut
        206892, --Zorn des Tigers
        206893, --Arkanes Geheimnis
        207199, --Trank: Fülle
        207200, --Trank: Grenzenloser Enthusiasmus
        207201, --Trank: Fürstliche Gestalt
        207202, --Trank: Klarer Gedanke
        207203, --Trank: Glückliches Ziel
        207204, --Trank: Rasender Sturm
        207205, --Trank: Verrückter Ausbruch
        207206, --Trank: Scharlachrote Liebe
        207207, --Trank: Beißende Widerwärtigkeit
        207208, --Trank: Gute Reise
        207273, --Grenzenloses Kraut
        207274, --Unendlicher Elementarstein
        207671, --Verteidigungstrank
        207672, --Stahltrank
        207673, --Reinigungstrank
        207674, --Göttlicher Heiltrank
        207675, --Wuttrank
        207676, --Fantastische Salbe
        207677, --Fantastischer Heiltrank
        207678, --Fantastischer Geist-Trank
        207679, --Fantastischer Manatrank
        207680, --Tödlicher Trank
        207681, --Starker magischer Trank
        207682, --Kettenschlag
        207683, --Berührung der magischen Kette
        207684, --Auslöschungstrank
        207685, --Löschtrank
        207686, --Göttlicher Blutschlag
        207687, --Heilige Berührung
        207953, --Erlösung des Phönix (1 Tag)
        207969, --Rhinozerosblut
        207970, --Kriegsinsignie
        207971, --Handbuch geheimer Rituale
        208072, --NULL
        208073, --NULL
        208213, --Kräuter der Allmacht
        208214, --Elementarstein der Allmacht
        208651, --Einfacher Produktionsglückstrank (1 Tag)
        208652, --Verbesserter Produktionsglückstrank (1 Tag)
        208653, --Produktionsglückstrank (7 Tage)
        208654, --Produktionsglückstrank (30 Tage)
        208655, --Einfacher Produktionsgeschwindigkeitstrank (1 Tag)
        208656, --Produktionsgeschwindigkeitstrank (7 Tage)
        208657, --Produktionsgeschwindigkeitstrank (30 Tage)
        208667, --Einfacher Sammelerfahrungstrank
        208668, --Einfacher Herstellungserfahrungstrank
        208762, --Glückstrank (30 Tage)
        208763, --Glückstrank (14 Tage)
        208764, --Glückstrank (7 Tage)
        208765, --Glückstrank (1 Tage)
        208766, --Glückstrank (7 Tage)
        208767, --Erfahrungstrank (30 Tage)
        208768, --Erfahrungstrank (14 Tage)
        208769, --Erfahrungstrank (7 Tage)
        208770, --Erfahrungstrank (7 Tage)
        208771, --Erfahrungstrank (1 Tag)
        208772, --Fertigkeitstrank (30 Tage)
        208773, --Fertigkeitstrank (14 Tage)
        208774, --Fertigkeitstrank (7 Tage)
        208779, --Engelsseufzer (30 Tage)
        208780, --Engelsseufzer (14 Tage)
        208781, --Engelsseufzer (7 Tage)
        208782, --Engelsseufzer (7 Tage)
        240373, --Geheimnisvoller Trank
        240374, --Hochgradig geheimnisvoller Trank
        240375, --Segnungstrank
        240376, --Präsent-Trank
        240377, --Barrieren-Elixir
        240378, --Windschutz-Elixir
        240379, --Berserkerelixier
        240380, --Esprit-Elixir
        240381, --Muskel-Elixir
        240382, --Fähigkeits-Elixir
        240383, --Elixir des Heiligen Lichts
        240426, --Flinker Heiltrank
        240427, --Trank der schnellen Auffassungsgabe
        240532, --Tödliches Gift
        240533, --Starker magischer Trank
        240534, --Auslöschungstrank
        240535, --Löschtrank
        241113, --Gesegneter Heiltrank
        241387, --Gebetsmanaquelle
        241407, --NULL
        241542, --NULL
        241543, --NULL
        241544, --NULL
        241545, --NULL
        241546, --NULL
        241547, --NULL
        241548, --NULL
        241549, --NULL
        241550, --NULL
        241551, --NULL
        241552, --NULL
        241553, --NULL
        241554, --NULL
        241555, --NULL
        241556, --NULL
        241557, --NULL
        241558, --NULL
        241559, --NULL
        241562, --NULL
        241563, --NULL
        241564, --NULL
        241565, --NULL
        241566, --NULL
        241567, --NULL
        241568, --NULL
        241569, --NULL
        241570, --NULL
        241571, --NULL
        241601, --Produktionsglückstrank (1 Tag)
        241602, --Produktionsgeschwindigkeitstrank (1 Tag)
        242085, --Steigerungstrank für die Sammelgeschwindigkeit
        242086, --Steigerungstrank für die Sammelerfahrung
        242087, --Steigerungstrank für die Sammelmenge
        242088, --Doppelfunktionstrank für Quests
        242089, --Questfertigkeitstrank
        242180, --Transformationstrank - Kogo
        242191, --Gesegneter Besserungstrank
        242192, --Gesegneter magischer Trank
        242222, --Stahlhauttrank
        242223, --Heiliger Trank
        242498, --Barrierentrank
        242499, --Windschutztrank
        242500, --Trank des Berserkers
        242501, --Trank des Geistesblitzes
        242502, --Muskeltrank
        242503, --Fähigkeitstrank
        242504, --Trank des Heiligen Lichts
        242628, --Doppelfunktionstrank für Tagesquests
        242629, --Fertigkeitstrank für Tagesquests
        242630, --Einfacher Doppelfunktionstrank für Tagesquests
        242631, --Einfacher Fertigkeitstrank für Tagesquests
        242686, --Herstellungserfahrungstrank
        242887, --Heiltrank der Lebenskraft
        242888, --Magischer Trank der Lebenskraft
        242889, --Trank der Rüstung
        242890, --Genesungstrank
        242891, --Heiltrank der Hoffnung
        242892, --Magischer Trank der Hoffnung
        242893, --Trank des Walls
        242894, --Trank der Seelenzähmung
        242895, --Quell der Heilung
        242896, --Magischer Trank der Quelle
        242897, --Trank des Felsens
        242898, --Flügeltrank
        242899, --Heiltrank der Erlösung
        242900, --Magischer Trank der Erlösung
        242901, --Trank des Eisenkämpfers
        242902, --Engelstrank
        243293, --Gelehrtentrank der Wohnsitz-Enzyklopädien (1 Tag)
        243294, --Gelehrtentrank der Wohnsitz-Enzyklopädien (7 Tage)
        243295, --Gelehrtentrank der Wohnsitz-Enzyklopädien (30 Tage)
        244108, --Transformationstrank - Schneemannkönig
        244109, --Transformationstrank - Eishexe
        244110, --Transformationstrank - Eishexe
        244111, --Transformationstrank - Phirius-Oheim
        244112, --Transformationstrank - Phirius-Oheim
        244357, --Trank der Macht I
        244358, --Trank der Macht II
        244371, --Sternenenergie-Trank
    },
    bossarrows = {
        note = "Boss Arrows",
        213744,
        211653,
    },
    bossthrowingknifes = {
        note = "Boss Throwing-Knifes",
        213743,
        211652,
    },
    arrows = {
        note = "Arrows",
        212989,
    },
    throwingknifes = {
        note = "Throwing Knifes",
        212984,
    },
    SHStuff = {
        note = "SHStuff",
        520030,
        520050,
        520070,
        520090,
        520110,
        520130,
        520150,
        520170,
        520190,
        520210,
        520230,
        242270,
        242266,
        242274,
    },
}

local function GetIDFn(key)
    if not ids[key] then
        return function() return false end
    end
    local tmp = {}
    for _, id in ipairs(ids[key]) do
        tmp[id] = true
    end
    return function(_, item) 
        return tmp[item.id] == true
    end
end
local function GetMultiIDFn(keys)
    local t = {}
    for k, v in pairs(keys) do
        t[v] = true
    end 

    local tmp = {}
    for k, v in pairs(ids) do
        if t[k] then
            for kk, id in pairs(ids[k]) do
                tmp[id] = true
            end
        end
    end
    return function(_, item) 
        return tmp[item.id] == true
    end
end

local out = {
    AllRes = {GetMultiIDFn({"ore", "wood", "herb"}), "All Ressources"},
    AllBufffood = {GetMultiIDFn({"Food", "Dessert", "Potion"}), "All Bufffood"}
}

for k, data in pairs(ids) do
    out[k] = {GetIDFn(k), data.note}
end

return out
