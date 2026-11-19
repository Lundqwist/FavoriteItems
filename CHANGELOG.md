# Changelog

## 1.3.0 (2026-11-19)

- **Disenchant warning**: starting to disenchant a favorite gives a raid warning, a sound and a pop-up while the cast is still going, with a **Stop casting** button (moving or Esc works too). If the cast finishes, the item is dropped from your favorites; if it's stopped, you get a "Phew" message.
- While you're choosing what to disenchant, a favorite's tooltip says "Don't disenchant this one!"
- **Mail warning**: attaching a favorite to a letter gives a warning and turns the **Send** button off until you pick **Remove it** or **Send anyway**. Letters sent by mass-mail addons skip the button; you get a chat message afterwards.
- Note: addons can't block a spell, so the disenchant warning comes during the cast. An instant disenchant from another addon only gets a message afterwards.

## 1.2.1 (2026-11-17)

- Removed the "Link to LunarMods" button; the minimap button and options page stay.
- CurseForge package and project avatar.

## 1.2.0 (2026-11-17)

- Minimap button (the heart): left-click starts or stops marking, hover shows how many favorites you have, right-click opens the options.
- Options page under Options → AddOns, and `/fav options`.

## 1.1.1 (2026-11-15)

- Hearts are redrawn reliably in the default bags.
- `/fav debug` shows what the addon finds in the open bag windows.

## 1.1.0 (2026-11-14)

- Favorites are specific items (saved by item GUID), not every copy of an item type. Favorites from 1.0.0 are moved over for the items in your bags.

## 1.0.0 (2026-11-14)

- First version: favorite hearts on bag items (Baganator or the default bags), mark mode, and a warning with a **Buy back** button when a favorite is sold.
