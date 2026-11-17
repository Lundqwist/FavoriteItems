<!-- Description for the CurseForge project page (paste as Markdown).
     Upload the PNGs in screenshots/ to the project's Images tab too; the
     links below point at the GitHub copies. -->

# FavoriteItems

**Mark items with a heart and get warned, with a buy-back button, when you sell one.**

Mark the items you care about with a little heart. If one of them ends up sold to a vendor anyway, FavoriteItems tells you right away and lets you buy it back with one click.

![With Baganator](https://raw.githubusercontent.com/Lundqwist/FavoriteItems/main/screenshots/baganator.png)

*With Baganator: hearts on favorite items, and the Favorites button in the bag window's bottom row.*

![Default bags](https://raw.githubusercontent.com/Lundqwist/FavoriteItems/main/screenshots/default-bags.png)

*With the default bags: the Favorites button under the combined backpack.*

## Features

- **Favorites button** on the lower side of your bags and bank.
- **Click to mark**: press the button, then click items to mark or unmark them. A heart appears in the icon's upper left corner. Press **Done** or close your bags when you're finished.
- **Specific items, not item types**: mark one copy of an item and the other copies stay unmarked.
- **Sold warning**: sell a favorite and a warning pops up with a **Buy back** button, plus a raid-warning message and sound. It catches every way of selling: right-click, dragging onto the vendor, and junk sellers.
- **Bought back = still a favorite**: buy it back before you leave the vendor and the heart comes back.
- **Tooltip line** showing "Favorite" on marked items.
- **Minimap button** (the heart): left-click starts or stops marking, hover shows how many favorites you have, right-click opens the options.

## Options

Right-click the minimap button, type `/fav options`, or open the game's Options → AddOns → FavoriteItems.

![FavoriteItems options](https://raw.githubusercontent.com/Lundqwist/FavoriteItems/main/screenshots/options.png)

- **Show the minimap button**: switch the heart button off if you'd rather use `/fav`.
- **Mark favorites** and **List them in chat**.
- **Link to LunarMods**: with [LunarMods](https://github.com/Lundqwist/LunarMods) installed, FavoriteItems can hand its minimap button over to LunarMods' **LM** button, which then opens it from its menu and shows your favorites count in its tooltip. **Unlink** gives the heart button back. LunarMods also switches the mod on and off in its `/lm` list. Without LunarMods, FavoriteItems works on its own.

## Commands

| Command | What it does |
|---|---|
| `/fav` or `/favorites` | Start or stop marking (opens your bags) |
| `/fav list` | List your favorites in chat |
| `/fav options` | Open the options |
| `/fav debug` | What the addon finds in the open bag windows |

## Compatibility

- Made for **World of Warcraft: Forever**.
- Works with **Baganator**: the heart is a Baganator corner widget, so you can move it under Baganator's settings → Icons.
- Without Baganator it uses the default bags and bank.
- Favorites and options are shared by all characters on your account.

## Source

GitHub: https://github.com/Lundqwist/FavoriteItems
