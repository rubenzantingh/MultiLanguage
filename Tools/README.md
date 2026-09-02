# Tools

## blizzard_import.py

Refreshes the databases from Blizzard's official Game Data API, so the addon
has a way to follow the game now that Wowhead blocks scraping.

It does not replace the scrape. It covers the part of the data that is plain
names, and leaves everything else alone.

### What it can and cannot do

Every line here was checked against the live API in September 2026, not read
from the documentation.

| | retail | classic |
|---|---|---|
| item names | yes, in bulk | yes, in bulk |
| spell names | yes, in bulk | no — the search returns nothing |
| quest titles | yes | no — every quest id answers 404 |
| quest descriptions | yes | no |
| **quest objectives** | **no** | **no** |
| **quest progress text** | **no** | **no** |
| **quest completion text** | **no** | **no** |
| npc names | tameable creatures and pets only | same |
| npc subnames | no — the field does not exist in the API | same |
| item and spell tooltips | one request each, `--with-details` | items only |

The three bold rows are the ones worth knowing about. Blizzard's quest endpoint
publishes a title and a description and nothing else, so the objective line,
the "are you done yet" line and the hand-in line cannot come from the API at
all. They are the most valuable thing in this database, and this script is
built so that a refresh cannot touch them.

The npc rows are worth knowing about too: `/data/wow/creature/` is effectively
a pet index. Of ids 1–59 only two resolve, and Thrall, Hogger and Innkeeper
Allison all answer 404. Ordinary quest givers are not in it, and there is no
subname field anywhere in the API.

### How it treats existing data

Everything is merged, never replaced wholesale:

* A field the API has no answer for keeps the value already on disk.
* A quest id the API does not know keeps its whole record.
* The `[q0]`-style quality markers on item names are carried over. The API
  knows nothing about that markup, so a name taken from it plainly would strip
  the marker off every item that has one — on a narrow test range that was
  2,482 items in a single language.

With markers preserved, a test sweep of about 5,000 Classic item ids found the
API and this database in exact agreement in German, Portuguese and Russian:
zero differences. So on ids the database already covers there is nothing to
gain — the value is in ids added since the last scrape, and in the retail
branch, where quests and spells are available too.

### Setup

Create an API client at <https://develop.battle.net/access/clients>. It is
free, takes about a minute, and needs only a Battle.net account. Any redirect
URL will do; this script never uses one.

```sh
cp blizzard.properties.example blizzard.properties
# put your own client id and secret in blizzard.properties
```

`blizzard.properties` is in `.gitignore`. Keep the secret out of the repository.

### Running it

Always look before you leap — `--dry-run` reports what would change and writes
nothing:

```sh
python Tools/blizzard_import.py --kind item --product classic --dry-run
python Tools/blizzard_import.py --kind item --product classic
```

Pass the `--product` that matches the branch you have checked out, or the data
will be merged from the wrong game. On the retail branch:

```sh
python Tools/blizzard_import.py --kind item  --product retail
python Tools/blizzard_import.py --kind spell --product retail
python Tools/blizzard_import.py --kind quest --product retail --max-id 90000
```

Useful flags:

* `--locales de,fr,pt` — only these languages. Defaults to all of them.
* `--max-id N` — stop early. Quests are asked for one id at a time, so this is
  the flag that decides how long a quest run takes.
* `--with-details` — also fetch tooltip text for items and spells. Correct, but
  one request per entity, so it is slow enough to leave running overnight.

Python 3.8 or newer. No third-party packages.

### Why searching is cheap and quests are not

The search endpoints return a full record per hit, up to 1000 per request, and
a record asked for without a `locale` parameter comes back with all twelve of
Blizzard's languages at once. So one request already holds every language pack.
Searching accepts an `id` range filter, which is what makes it possible to walk
past the 1000-result ceiling: the script widens and halves its window as the id
space thins out and thickens.

Quests have no search index at all — `/data/wow/search/quest` is a bare 404 with
an empty body — so they are asked for one id at a time and most ids do not
exist. That is why quest runs are slow and why `--max-id` matters.
