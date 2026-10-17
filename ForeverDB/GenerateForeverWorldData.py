import csv
import re
from pathlib import Path


# ============================================================
# CONFIGURATION
# ============================================================

BASE_DIR = Path(__file__).resolve().parent

ITEM_CSV = BASE_DIR / "Item.csv"
ITEM_SPARSE_CSV = BASE_DIR / "ItemSparse.csv"
ITEM_APPEARANCE_CSV = BASE_DIR / "ItemAppearance.csv"
ITEM_MODIFIED_APPEARANCE_CSV = BASE_DIR / "ItemModifiedAppearance.csv"

OUTPUT_LUA = BASE_DIR / "ForeverWorldData.lua"


# ============================================================
# HELPERS
# ============================================================

def clean(value):
    if value is None:
        return ""

    return str(value).strip()


def to_int(value, default=0):
    try:
        return int(float(value))
    except (ValueError, TypeError):
        return default


def lua_string(value):
    value = clean(value)

    value = value.replace("\\", "\\\\")
    value = value.replace('"', '\\"')
    value = value.replace("\r", "")
    value = value.replace("\n", " ")

    return '"' + value + '"'


# ============================================================
# FILTER INTERNAL / OLD / TEST ITEMS
# ============================================================

def is_filtered_name(name):
    if not name:
        return False

    n = name.strip().lower()

    # --------------------------------------------------------
    # Exact names
    # --------------------------------------------------------

    exact_names = {
        "test",
        "test item",
        "qa",
        "dnt",
        "unused",
        "not used",
        "deprecated",
        "placeholder",
        "dummy",
        "temp",
        "temporary",
        "null",
    }

    if n in exact_names:
        return True

    # --------------------------------------------------------
    # Bracketed/internal markers
    #
    # This catches:
    #
    # [old] Sword
    # Sword [old]
    # [OLD] Sword
    # [test] Item
    # --------------------------------------------------------

    internal_markers = [
        "[test]",
        "[qa]",
        "[dnt]",
        "[old]",
        "[unused]",
        "[placeholder]",
        "[deprecated]",
        "[dummy]",
        "[temp]",
        "[temporary]",
        "[internal]",
        "[debug]",
        "[dev]",
        "[development]",
        "[do not use]",
    ]

    for marker in internal_markers:
        if marker in n:
            return True

    # --------------------------------------------------------
    # Prefixes
    # --------------------------------------------------------

    prefixes = [
        "test ",
        "test_",
        "test-",

        "qa ",
        "qa_",
        "qa-",

        "dnt ",
        "dnt_",
        "dnt-",

        "unused ",
        "unused_",
        "unused-",

        "placeholder ",
        "placeholder_",
        "placeholder-",

        "dummy ",
        "dummy_",
        "dummy-",

        "temp ",
        "temp_",
        "temp-",

        "temporary ",
        "temporary_",
        "temporary-",

        "deprecated ",
        "deprecated_",
        "deprecated-",

        "old ",
        "old_",
        "old-",

        "zzold ",
        "zzold_",
        "zzold-",

        "npc ",
        "npc_",
        "npc-",

        "monster ",
        "monster_",
        "monster-",
    ]

    for prefix in prefixes:
        if n.startswith(prefix):
            return True

    # --------------------------------------------------------
    # Suffixes
    # --------------------------------------------------------

    suffixes = [
        " dnt",
        "_dnt",
        "-dnt",

        " unused",
        "_unused",
        "-unused",

        " placeholder",
        "_placeholder",
        "-placeholder",

        " deprecated",
        "_deprecated",
        "-deprecated",

        " old",
        "_old",
        "-old",

        " dnt",
        "_dnt",
        "-dnt",
    ]

    for suffix in suffixes:
        if n.endswith(suffix):
            return True

    # --------------------------------------------------------
    # Other common internal patterns
    # --------------------------------------------------------

    patterns = [
        r"^test[\s_\-]*",
        r"^qa[\s_\-]*",
        r"^dnt[\s_\-]*",
        r"^unused[\s_\-]*",
        r"^not[\s_\-]*used[\s_\-]*",
        r"^placeholder[\s_\-]*",
        r"^dummy[\s_\-]*",
        r"^temp[\s_\-]*",
        r"^temporary[\s_\-]*",
        r"^deprecated[\s_\-]*",
        r"^zzold[\s_\-]*",
        r"^old[\s_\-]+",
        r"^ph[\s_\-]+",
        r"^npc[\s_\-]*",
        r"^monster[\s_\-]*",

        r"[\s_\-]+dnt$",
        r"[\s_\-]+unused$",
        r"[\s_\-]+placeholder$",
        r"[\s_\-]+deprecated$",
        r"[\s_\-]+old$",
    ]

    for pattern in patterns:
        if re.search(pattern, n):
            return True

    return False


# ============================================================
# READ CSV
# ============================================================

def read_csv(path):
    print("Reading:", path.name)

    if not path.exists():
        print("WARNING: Missing file:", path.name)
        return []

    with path.open(
        "r",
        encoding="utf-8-sig",
        newline=""
    ) as f:

        reader = csv.DictReader(f)

        rows = list(reader)

    print("  Rows:", len(rows))

    return rows


# ============================================================
# LOAD DATA
# ============================================================

print()
print("==============================================")
print(" ForeverDB World Database Generator")
print("==============================================")
print()


item_rows = read_csv(ITEM_CSV)
sparse_rows = read_csv(ITEM_SPARSE_CSV)
appearance_rows = read_csv(ITEM_APPEARANCE_CSV)
modified_rows = read_csv(ITEM_MODIFIED_APPEARANCE_CSV)


# ============================================================
# BUILD ITEM LOOKUP
# ============================================================

item_by_id = {}

for row in item_rows:

    item_id = to_int(row.get("ID"))

    if item_id <= 0:
        continue

    item_by_id[item_id] = row


# ============================================================
# BUILD ITEM SPARSE LOOKUP
# ============================================================

sparse_by_id = {}

for row in sparse_rows:

    item_id = to_int(row.get("ID"))

    if item_id <= 0:
        continue

    sparse_by_id[item_id] = row


# ============================================================
# BUILD APPEARANCE LOOKUP
# ============================================================

appearance_by_id = {}

for row in appearance_rows:

    appearance_id = to_int(row.get("ID"))

    if appearance_id <= 0:
        continue

    appearance_by_id[appearance_id] = row


# ============================================================
# BUILD ITEM MODIFIED APPEARANCE LOOKUP
# ============================================================

item_appearance_by_item_id = {}

for row in modified_rows:

    item_id = to_int(row.get("ItemID"))

    if item_id <= 0:
        continue

    appearance_id = to_int(
        row.get("ItemAppearanceID")
    )

    if appearance_id <= 0:
        continue

    # Keep the first valid appearance.
    if item_id not in item_appearance_by_item_id:
        item_appearance_by_item_id[item_id] = appearance_id


# ============================================================
# GENERATE WORLD ITEMS
# ============================================================

world_items = {}

total_items = 0
included_items = 0
filtered_items = 0
missing_sparse = 0

direct_icon_count = 0
appearance_icon_count = 0
no_icon_count = 0


print()
print("Building world item database...")
print()


for item_id, item_row in item_by_id.items():

    total_items += 1

    # --------------------------------------------------------
    # Find ItemSparse
    # --------------------------------------------------------

    sparse = sparse_by_id.get(item_id)

    if sparse is None:
        missing_sparse += 1
        continue

    # --------------------------------------------------------
    # Get item name
    # --------------------------------------------------------

    name = clean(
        sparse.get("Display_lang")
    )

    if not name:
        name = clean(
            sparse.get("Name_lang")
        )

    if not name:
        name = "Unknown Item"

    # --------------------------------------------------------
    # Filter internal/old/test items
    # --------------------------------------------------------

    if is_filtered_name(name):

        filtered_items += 1

        continue

    # --------------------------------------------------------
    # Basic item information
    # --------------------------------------------------------

    class_id = to_int(
        item_row.get("ClassID")
    )

    subclass_id = to_int(
        item_row.get("SubclassID")
    )

    inventory_type = to_int(
        item_row.get("InventoryType")
    )

    material = to_int(
        item_row.get("Material")
    )

    sheathe_type = to_int(
        item_row.get("SheatheType")
    )

    expansion_id = to_int(
        sparse.get("ExpansionID")
    )

    item_level = to_int(
        sparse.get("ItemLevel")
    )

    required_level = to_int(
        sparse.get("RequiredLevel")
    )

    quality = to_int(
        sparse.get("OverallQualityID")
    )

    sell_price = to_int(
        sparse.get("SellPrice")
    )

    buy_price = to_int(
        sparse.get("BuyPrice")
    )

    bonding = to_int(
        sparse.get("Bonding")
    )

    container_slots = to_int(
        sparse.get("ContainerSlots")
    )

    # --------------------------------------------------------
    # ICON
    #
    # First:
    # Item.csv IconFileDataID
    #
    # Fallback:
    # ItemAppearance DefaultIconFileDataID
    # --------------------------------------------------------

    icon_file_data_id = to_int(
        item_row.get("IconFileDataID")
    )

    icon_source = "none"

    appearance_id = 0
    display_id = 0

    # --------------------------------------------------------
    # Direct icon from Item.csv
    # --------------------------------------------------------

    if icon_file_data_id > 0:

        direct_icon_count += 1

        icon_source = "item"

    else:

        # ----------------------------------------------------
        # Appearance fallback
        # ----------------------------------------------------

        appearance_id = item_appearance_by_item_id.get(
            item_id,
            0
        )

        appearance = appearance_by_id.get(
            appearance_id
        )

        if appearance:

            display_id = to_int(
                appearance.get("ItemDisplayInfoID")
            )

            icon_file_data_id = to_int(
                appearance.get("DefaultIconFileDataID")
            )

            if icon_file_data_id > 0:

                appearance_icon_count += 1

                icon_source = "appearance"

    if icon_file_data_id <= 0:

        no_icon_count += 1

    # --------------------------------------------------------
    # Build item record
    # --------------------------------------------------------

    world_items[item_id] = {
        "itemID": item_id,
        "name": name,

        "classID": class_id,
        "subclassID": subclass_id,

        "inventoryType": inventory_type,
        "material": material,
        "sheatheType": sheathe_type,

        "expansionID": expansion_id,

        "itemLevel": item_level,
        "requiredLevel": required_level,

        "quality": quality,

        "sellPrice": sell_price,
        "buyPrice": buy_price,

        "bonding": bonding,
        "containerSlots": container_slots,

        "appearanceID": appearance_id,
        "displayID": display_id,

        "iconFileDataID": icon_file_data_id,
        "iconSource": icon_source,
    }

    included_items += 1


# ============================================================
# WRITE LUA
# ============================================================

print()
print("Writing:", OUTPUT_LUA.name)
print()


with OUTPUT_LUA.open(
    "w",
    encoding="utf-8",
    newline="\n"
) as f:

    f.write("--====================================================\n")
    f.write("-- ForeverDB World Database\n")
    f.write("-- Generated automatically\n")
    f.write("-- DO NOT EDIT MANUALLY\n")
    f.write("--====================================================\n\n")

    f.write("ForeverWorldData = {\n")
    f.write("    items = {\n")

    for item_id in sorted(world_items.keys()):

        item = world_items[item_id]

        f.write(
            "        [%d] = {\n"
            % item_id
        )

        f.write(
            "            itemID = %d,\n"
            % item["itemID"]
        )

        f.write(
            "            name = %s,\n"
            % lua_string(item["name"])
        )

        f.write(
            "            classID = %d,\n"
            % item["classID"]
        )

        f.write(
            "            subclassID = %d,\n"
            % item["subclassID"]
        )

        f.write(
            "            inventoryType = %d,\n"
            % item["inventoryType"]
        )

        f.write(
            "            material = %d,\n"
            % item["material"]
        )

        f.write(
            "            sheatheType = %d,\n"
            % item["sheatheType"]
        )

        f.write(
            "            expansionID = %d,\n"
            % item["expansionID"]
        )

        f.write(
            "            itemLevel = %d,\n"
            % item["itemLevel"]
        )

        f.write(
            "            requiredLevel = %d,\n"
            % item["requiredLevel"]
        )

        f.write(
            "            quality = %d,\n"
            % item["quality"]
        )

        f.write(
            "            sellPrice = %d,\n"
            % item["sellPrice"]
        )

        f.write(
            "            buyPrice = %d,\n"
            % item["buyPrice"]
        )

        f.write(
            "            bonding = %d,\n"
            % item["bonding"]
        )

        f.write(
            "            containerSlots = %d,\n"
            % item["containerSlots"]
        )

        f.write(
            "            appearanceID = %d,\n"
            % item["appearanceID"]
        )

        f.write(
            "            displayID = %d,\n"
            % item["displayID"]
        )

        f.write(
            "            iconFileDataID = %d,\n"
            % item["iconFileDataID"]
        )

        f.write(
            "            iconSource = %s,\n"
            % lua_string(item["iconSource"])
        )

        f.write("        },\n")

    f.write("    },\n")
    f.write("}\n")


# ============================================================
# SUMMARY
# ============================================================

print("==============================================")
print(" Generation Complete")
print("==============================================")
print()

print(
    "Total Item.csv records:       %d"
    % total_items
)

print(
    "Included world items:         %d"
    % included_items
)

print(
    "Filtered internal/old items:  %d"
    % filtered_items
)

print(
    "Missing ItemSparse records:   %d"
    % missing_sparse
)

print()

print(
    "Direct Item.csv icons:         %d"
    % direct_icon_count
)

print(
    "Appearance fallback icons:    %d"
    % appearance_icon_count
)

print(
    "Items without icon:            %d"
    % no_icon_count
)

print()


# ============================================================
# TEST ITEMS
# ============================================================

print("==============================================")
print(" Test Items")
print("==============================================")
print()


TEST_IDS = [
    25,
    2770,
]


for test_id in TEST_IDS:

    print("TEST ITEM:", test_id)

    item = world_items.get(test_id)

    if item is None:

        print("  NOT FOUND / FILTERED")

        print()

        continue

    print(
        "  Name:",
        item["name"]
    )

    print(
        "  Class:",
        item["classID"]
    )

    print(
        "  Subclass:",
        item["subclassID"]
    )

    print(
        "  Expansion:",
        item["expansionID"]
    )

    print(
        "  Item Level:",
        item["itemLevel"]
    )

    print(
        "  Quality:",
        item["quality"]
    )

    print(
        "  Appearance:",
        item["appearanceID"]
    )

    print(
        "  Display:",
        item["displayID"]
    )

    print(
        "  Icon FileDataID:",
        item["iconFileDataID"]
    )

    print(
        "  Icon Source:",
        item["iconSource"]
    )

    print()


# ============================================================
# CHECK FOR OLD ITEMS THAT SLIPPED THROUGH
# ============================================================

print("==============================================")
print(" Checking For Old/Test Items")
print("==============================================")
print()

old_remaining = []

for item_id, item in world_items.items():

    name = item.get("name", "")

    if is_filtered_name(name):

        old_remaining.append(
            (item_id, name)
        )


if old_remaining:

    print(
        "WARNING:",
        len(old_remaining),
        "filtered-looking items remain!"
    )

    for item_id, name in old_remaining[:50]:

        print(
            "  ",
            item_id,
            name
        )

else:

    print(
        "No obvious old/test/internal items found."
    )

print()

print("Database written to:")
print(OUTPUT_LUA)

print()
print("Done.")