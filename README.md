# FavoriteItems

A World of Warcraft: Forever addon (interface 16001) for marking favorite items.

- A **Favorites** button sits on the lower side of the bag window (in Baganator's bottom button row) and under the bank window.
- Click it, then click items to mark or unmark them. Favorites get a small heart in the icon's upper left corner. Click **Done** (or close the bags) to stop.
- Sell a favorite to a merchant and a warning pops up, with a **Buy back** button while the merchant is still open. A raid-warning message and sound go with it.
- Item tooltips show a "Favorite" line.
- `/fav` toggles marking (opens your bags), `/fav list` lists favorites.

Favorites are specific items, not item types: each is saved by its item GUID in `FavoriteItemsDB`, so marking one copy of an item leaves the other copies unmarked. Only items the current character holds (bags, or the bank while it's open) can be marked; other characters' bags shown from Baganator's cache can't. If a sold favorite is bought back while the merchant is still open, it's marked again.

Works with Baganator (heart is a Baganator corner widget: it can be moved under Baganator's settings → Icons) and falls back to the default Blizzard bags and bank when Baganator isn't enabled.

Install: run `.\install.ps1`, then `/reload` in game.
