# FavoriteItems

A World of Warcraft: Forever addon (interface 16001) for marking favorite items.

![FavoriteItems with Baganator: hearts on favorite items and the Favorites button in the bottom row](screenshots/baganator.png)

*With Baganator: favorites get a heart, and the **Favorites** button sits in the bag window's bottom row.*

![FavoriteItems with the default bags: the Favorites button under the combined backpack](screenshots/default-bags.png)

*Without Baganator: the **Favorites** button sits under the default combined backpack.*

## Features

- A **Favorites** button sits on the lower side of the bag window (in Baganator's bottom button row, or under the default bags) and under the bank window.
- Click it, then click items to mark or unmark them. Favorites get a small heart in the icon's upper left corner. Click **Done** (or close the bags) to stop.
- Sell a favorite to a merchant and a warning pops up, with a **Buy back** button while the merchant is still open. A raid-warning message and sound go with it.
- Item tooltips show a "Favorite" line.
- `/fav` toggles marking (opens your bags), `/fav list` lists favorites, `/fav debug` shows what the addon finds in the open bag windows.

Favorites are specific items, not item types: each is saved by its item GUID in `FavoriteItemsDB`, so marking one copy of an item leaves the other copies unmarked. Only items the current character holds (bags, or the bank while it's open) can be marked; other characters' bags shown from Baganator's cache can't. If a sold favorite is bought back while the merchant is still open, it's marked again.

Works with Baganator (heart is a Baganator corner widget: it can be moved under Baganator's settings → Icons) and falls back to the default Blizzard bags and bank when Baganator isn't enabled.

## Install

Copy the `FavoriteItems` folder (with `FavoriteItems.toc`, `FavoriteItems.lua` and `Media`) into `World of Warcraft\_forever_\Interface\AddOns\`, or run `.\install.ps1` from a clone. Then `/reload` in game.

The description for CurseForge is in [CURSEFORGE.md](CURSEFORGE.md).
