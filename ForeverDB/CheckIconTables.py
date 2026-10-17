import csv
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

FILES = [
    "ItemAppearance.csv",
    "ItemModifiedAppearance.csv",
    "ItemDisplayInfo.csv",
]

for filename in FILES:

    path = os.path.join(BASE_DIR, filename)

    print("")
    print("=" * 70)
    print(filename)
    print("=" * 70)

    if not os.path.exists(path):
        print("FILE NOT FOUND")
        continue

    with open(
        path,
        "r",
        encoding="utf-8-sig",
        newline=""
    ) as f:

        reader = csv.reader(f)

        rows = list(reader)

    if not rows:
        print("EMPTY")
        continue

    headers = rows[0]

    print("")
    print("COLUMNS:")
    print("")

    for i, header in enumerate(headers):
        print(
            "%3d : %s"
            % (i, header)
        )

    print("")
    print("FIRST 5 DATA ROWS:")
    print("")

    for row in rows[1:6]:

        print(row)

print("")
print("=" * 70)
print("DONE")
print("=" * 70)

input("\nPress Enter to close...")