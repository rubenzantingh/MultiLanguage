#!/usr/bin/env python3
"""Refresh the MultiLanguage databases from Blizzard's official Game Data API.

Wowhead now blocks scraping, so the database has no way to follow the game. The
official API can carry part of the load. It is free, it is meant for addon
authors, and -- the part that matters most here -- a record asked for without a
locale comes back with every language at once, so one request already holds all
eleven packs.

It cannot carry all of it, and the accounting matters more than the code. Every
line below was checked against the live API in September 2026 rather than read
from the documentation:

                        retail          classic
    item names          yes, in bulk    yes, in bulk
    spell names         yes, in bulk    no (the search returns nothing)
    quest titles        yes             no (every quest id answers 404)
    quest descriptions  yes             no
    quest objectives    NO -- not published for any game
    quest progress      NO
    quest completion    NO
    npc names           only tameable creatures and pets, so in practice no
    npc subnames        NO -- no such field exists anywhere in the API
    item tooltips       one request per item, see --with-details
    spell tooltips      one request per spell, see --with-details

So this refreshes the parts that are plain names and leaves everything else
exactly as it is. What it writes is merged into what is already on disk: a
field the API has no answer for keeps the value the database already holds.
Running this can add and correct. It never deletes.

That last point is deliberate. The objective, progress and completion lines are
the most valuable thing in this database and the API has none of them, so they
must survive a refresh untouched.

Setup
-----
Create an API client at https://develop.battle.net/access/clients -- free, and
about a minute of work. Then:

    cp blizzard.properties.example blizzard.properties
    # put your own client id and secret in blizzard.properties
    python Tools/blizzard_import.py --kind item --product classic --dry-run
    python Tools/blizzard_import.py --kind item --product classic

blizzard.properties is in .gitignore and must stay out of the repository.

On the retail branch, quests and spells are worth running too:

    python Tools/blizzard_import.py --kind spell --product retail
    python Tools/blizzard_import.py --kind quest --product retail --max-id 90000

Python 3.8 or newer. No third-party packages.
"""
import argparse
import base64
import json
import pathlib
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]

# addon code -> (Blizzard locale, the file name this repository uses)
#
# Blizzard also returns en_GB. It is ignored: this addon has no separate
# British pack, and the two differ on almost nothing.
LOCALES = {
    "en": ("en_US", "enUS"), "de": ("de_DE", "deDE"), "es": ("es_ES", "esES"),
    "mx": ("es_MX", "esMX"), "fr": ("fr_FR", "frFR"), "it": ("it_IT", "itIT"),
    "pt": ("pt_BR", "ptBR"), "ru": ("ru_RU", "ruRU"), "ko": ("ko_KR", "koKR"),
    "cn": ("zh_CN", "zhCN"), "tw": ("zh_TW", "zhTW"),
}

KINDS = {
    "item": {
        "table": "itemData", "folder": "Items",
        "search": "/data/wow/search/item", "ceiling": 260000,
        "fields": ["name", "additional_info"],
    },
    "spell": {
        "table": "spellData", "folder": "Spells",
        "search": "/data/wow/search/spell", "ceiling": 500000,
        "fields": ["name", "additional_info"],
    },
    "npc": {
        "table": "npcData", "folder": "Npcs",
        "search": "/data/wow/search/creature", "ceiling": 260000,
        "fields": ["name", "subname"],
    },
    "quest": {
        # There is no quest search index: /data/wow/search/quest is a bare 404
        # with an empty body, which is the API's shape for "no such index".
        # Quests have to be asked for one id at a time.
        "table": "questData", "folder": "Quests",
        "search": None, "ceiling": 90000,
        "fields": ["title", "objective", "description", "progress",
                   "completion", "rewards"],
    },
}

PRODUCTS = {"retail": "static", "classic": "static-classic1x"}

# A search answers with at most 1000 rows however large a page you ask for, so
# the id space is walked in windows. When a window overflows the response says
# so and the window is halved.
PAGE_SIZE = 1000


def read_properties(path):
    """Read KEY=VALUE lines. Blank lines and # comments are ignored."""
    if not path.exists():
        sys.exit(
            f"{path.name} not found.\n\n"
            f"Copy blizzard.properties.example to {path.name} and put your own\n"
            "client id and secret in it. A client is free to create at\n"
            "https://develop.battle.net/access/clients"
        )
    values = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip('"').strip("'")
    return values


class Api:
    def __init__(self, client_id, client_secret, region, product):
        self.region = region
        self.namespace = f"{PRODUCTS[product]}-{region}"
        self.token = self._token(client_id, client_secret)

    def _token(self, client_id, client_secret):
        auth = base64.b64encode(f"{client_id}:{client_secret}".encode()).decode()
        request = urllib.request.Request(
            "https://oauth.battle.net/token",
            data=b"grant_type=client_credentials",
            headers={"Authorization": f"Basic {auth}"},
        )
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                return json.load(response)["access_token"]
        except urllib.error.HTTPError as error:
            sys.exit(f"could not get a token ({error.code}). Check the client id "
                     "and secret in blizzard.properties.")

    def get(self, path, params, retries=4):
        """GET with a short backoff. None on 404, which is ordinary: both quest
        ids and entity ids are sparse, and most ids simply do not exist."""
        url = (f"https://{self.region}.api.blizzard.com{path}?"
               + urllib.parse.urlencode(params))
        for attempt in range(retries):
            request = urllib.request.Request(
                url, headers={"Authorization": f"Bearer {self.token}"})
            try:
                with urllib.request.urlopen(request, timeout=30) as response:
                    return json.load(response)
            except urllib.error.HTTPError as error:
                if error.code == 404:
                    return None
                if error.code in (429, 500, 502, 503, 504):
                    time.sleep(2 ** attempt)
                    continue
                return None
            except Exception:
                time.sleep(2 ** attempt)
        return None


def localised(field):
    """Pull {addon code: text} out of one of Blizzard's per-locale objects."""
    if not isinstance(field, dict):
        return {}
    out = {}
    for code, (blizzard, _) in LOCALES.items():
        value = field.get(blizzard)
        if isinstance(value, str) and value.strip():
            out[code] = value.strip()
    return out


def fetch_search(api, kind, verbose=True):
    """Walk the id space of a searchable kind. Yields (id, {code: {field: text}})."""
    spec = KINDS[kind]
    window, low, seen = 4000, 0, 0
    while low < spec["ceiling"]:
        high = low + window
        page = api.get(spec["search"], {
            "namespace": api.namespace, "id": f"[{low},{high}]",
            "orderby": "id", "_page": 1, "_pageSize": PAGE_SIZE,
        })
        if page is None:
            low = high
            continue
        # The response flags when it hit the 1000-row ceiling. Halving the
        # window and asking again is the only way to be sure nothing was lost.
        if page.get("resultCountCapped") and window > 1:
            window = max(1, window // 2)
            continue
        results = page.get("results", [])
        for hit in results:
            data = hit.get("data") or {}
            entity_id = data.get("id")
            names = localised(data.get("name"))
            if entity_id and names:
                seen += 1
                yield entity_id, {c: {"name": t} for c, t in names.items()}
        if verbose and results:
            print(f"  ids {low}-{high}: {len(results)} (running total {seen})",
                  flush=True)
        low = high
        # Thinning ids: widen again so the walk does not crawl.
        if len(results) < PAGE_SIZE // 4 and window < 32000:
            window *= 2


def fetch_quests(api, max_id, verbose=True):
    """Quests have no search index, so each id is asked for on its own.

    Only the title and the description come back. The objective line, the
    in-progress line and the hand-in line are not published at all, so they are
    never in the result and the merge leaves the existing values alone.
    """
    found = 0
    for quest_id in range(1, max_id + 1):
        record = api.get(f"/data/wow/quest/{quest_id}", {"namespace": api.namespace})
        if record:
            titles = localised(record.get("title"))
            descriptions = localised(record.get("description"))
            row = {}
            for code in LOCALES:
                fields = {}
                if code in titles:
                    fields["title"] = titles[code]
                if code in descriptions:
                    fields["description"] = descriptions[code]
                if fields:
                    row[code] = fields
            if row:
                found += 1
                yield quest_id, row
        if verbose and quest_id % 2000 == 0:
            print(f"  quest {quest_id}/{max_id}, {found} found so far", flush=True)


def fetch_details(api, kind, ids, verbose=True):
    """Tooltip text for items and spells, one request each.

    A spell's description sits on its detail record, in every locale. An item
    has no description of its own; the tooltip line lives under preview_item,
    and only some items have one. Tens of thousands of requests, which is why
    this is behind a flag.
    """
    path = "/data/wow/spell/{}" if kind == "spell" else "/data/wow/item/{}"
    ids = list(ids)
    for index, entity_id in enumerate(ids):
        record = api.get(path.format(entity_id), {"namespace": api.namespace})
        if not record:
            continue
        if kind == "spell":
            text = localised(record.get("description"))
        else:
            spells = (record.get("preview_item") or {}).get("spells") or []
            text = localised(spells[0].get("description")) if spells else {}
        if text:
            yield entity_id, {c: {"additional_info": v} for c, v in text.items()}
        if verbose and index and index % 1000 == 0:
            print(f"  details {index}/{len(ids)}", flush=True)


# --- the addon's own Lua tables ---------------------------------------------

ROW = re.compile(r"^\[(\d+)\] = \{(.*)\},?\s*$")
FIELD = re.compile(r"(\w+) = (nil|\"(?:\\.|[^\"\\])*\")")


def lua_path(kind, code):
    return ROOT / "Database" / KINDS[kind]["folder"] / f"{LOCALES[code][1]}.lua"


def unquote(raw):
    return (raw[1:-1].replace("\\n", "\n").replace('\\"', '"')
            .replace("\\\\", "\\"))


def quote(value):
    if value is None:
        return "nil"
    text = (str(value).replace("\\", "\\\\").replace('"', '\\"')
            .replace("\r", "").replace("\n", "\\n"))
    return f'"{text}"'


def read_existing(kind, code):
    """Everything the database already holds, so the merge can keep it."""
    path = lua_path(kind, code)
    rows = {}
    if not path.exists():
        return rows
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        match = ROW.match(line.strip())
        if not match:
            continue
        fields = {}
        for name, raw in FIELD.findall(match.group(2)):
            if raw != "nil":
                fields[name] = unquote(raw)
        rows[int(match.group(1))] = fields
    return rows


def write_lua(kind, code, rows):
    """Rewrite one language's file, in exactly the shape the addon already uses."""
    spec = KINDS[kind]
    path = lua_path(kind, code)
    lines = ["local addonName, addonTable = ...", "",
             f"addonTable.{spec['table']}['{code}'] = {{"]
    written = 0
    for entity_id in sorted(rows):
        fields = rows[entity_id]
        parts = [f"{name} = {quote(fields.get(name))}"
                 for name in spec["fields"] if name in fields]
        if not parts:
            continue
        lines.append(f"[{entity_id}] = {{" + ", ".join(parts) + "},")
        written += 1
    lines.append("}")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return written


# Item names in this database carry a leading quality marker -- "[q0]Recruit's
# Pants" -- which the addon reads to colour the tooltip. The API knows nothing
# about that markup, so a name taken from it plainly would strip the marker off
# every item that has one. On a narrow test range that was 2,482 items in a
# single language. The marker is therefore carried across.
MARKER = re.compile(r"^(\[q\d+\])")


def keep_markup(old, new):
    """Put the old value's leading [qN] marker back on a new value."""
    if not isinstance(old, str) or not isinstance(new, str):
        return new
    match = MARKER.match(old)
    if match and not MARKER.match(new):
        return match.group(1) + new
    return new


def merge(existing, fetched):
    """Fetched values win where they exist; everything else is kept.

    The API publishes no objective, progress or completion line, so those are
    never in `fetched` and always survive from `existing`. Nothing is deleted,
    and inline markup the API does not model is carried over rather than lost.
    """
    out = {entity_id: dict(fields) for entity_id, fields in existing.items()}
    added = changed = 0
    for entity_id, fields in fetched.items():
        row = out.get(entity_id)
        if row is None:
            out[entity_id] = dict(fields)
            added += 1
            continue
        incoming = {name: keep_markup(row.get(name), value)
                    for name, value in fields.items()}
        if any(row.get(name) != value for name, value in incoming.items()):
            changed += 1
        row.update(incoming)
    return out, added, changed


def main():
    parser = argparse.ArgumentParser(
        description="Refresh the MultiLanguage databases from Blizzard's Game Data API.")
    parser.add_argument("--kind", required=True, choices=sorted(KINDS))
    parser.add_argument("--product", default="retail", choices=sorted(PRODUCTS),
                        help="which game the checked-out branch is for")
    parser.add_argument("--region", default=None, choices=["eu", "us"])
    parser.add_argument("--locales", default=",".join(LOCALES),
                        help="comma separated addon language codes")
    parser.add_argument("--max-id", type=int, help="stop at this id")
    parser.add_argument("--with-details", action="store_true",
                        help="also fetch item and spell tooltip text: correct, "
                             "but one request per entity and very slow")
    parser.add_argument("--dry-run", action="store_true",
                        help="report what would change and write nothing")
    args = parser.parse_args()

    if args.kind == "quest" and args.product == "classic":
        sys.exit("The API has no quest data for Classic: every /data/wow/quest/<id>\n"
                 "answers 404 on the Classic namespace. Nothing to do.")
    if args.kind == "spell" and args.product == "classic":
        print("warning: the spell search returns nothing on the Classic namespace.\n"
              "         Expect zero results.", file=sys.stderr)
    if args.kind == "npc":
        print("warning: only tameable creatures and pets are in the creature API,\n"
              "         and it has no subname field at all. Ordinary quest givers\n"
              "         cannot be fetched. This will refresh very little.",
              file=sys.stderr)

    properties = read_properties(ROOT / "blizzard.properties")
    client_id = properties.get("client_id")
    client_secret = properties.get("client_secret")
    if not client_id or not client_secret:
        sys.exit("blizzard.properties needs both client_id and client_secret.")
    region = args.region or properties.get("region", "eu")

    wanted = [c.strip() for c in args.locales.split(",") if c.strip() in LOCALES]
    if not wanted:
        sys.exit("no known language codes in --locales. Known: "
                 + ", ".join(LOCALES))

    api = Api(client_id, client_secret, region, args.product)
    print(f"{args.kind}: {api.namespace}")

    fetched = {}
    if args.kind == "quest":
        source = fetch_quests(api, args.max_id or KINDS["quest"]["ceiling"])
    else:
        source = fetch_search(api, args.kind)
    for entity_id, per_locale in source:
        fetched[entity_id] = per_locale
    print(f"{args.kind}: {len(fetched)} records from the API")

    if args.with_details and args.kind in ("item", "spell"):
        print(f"{args.kind}: fetching tooltip text, one request per entity")
        for entity_id, per_locale in fetch_details(api, args.kind, sorted(fetched)):
            for code, fields in per_locale.items():
                fetched.setdefault(entity_id, {}).setdefault(code, {}).update(fields)

    for code in wanted:
        rows = {entity_id: per_locale[code]
                for entity_id, per_locale in fetched.items() if code in per_locale}
        existing = read_existing(args.kind, code)
        if not existing and not lua_path(args.kind, code).exists():
            print(f"  {code}: {lua_path(args.kind, code).name} does not exist, skipped")
            continue
        merged, added, changed = merge(existing, rows)
        print(f"  {code}: had {len(existing)}, API gave {len(rows)}, "
              f"{added} new, {changed} changed, {len(merged)} total")
        if not args.dry_run:
            print(f"  {code}: wrote {write_lua(args.kind, code, merged)} rows")
    if args.dry_run:
        print("dry run, nothing written")


if __name__ == "__main__":
    main()
