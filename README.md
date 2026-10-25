# LetterMemory

**A memory game that pairs a letter — or a syllable — with its picture.** Flip two cards; a match
is a **letter** (or the word's first **syllable**) and the **picture** it belongs to (like
[LetterDetective](https://github.com/mesopelagique/LetterDetective), but from memory). Bilingual
🇫🇷 / 🇬🇧. Built on [Hero](https://github.com/mesopelagique/Hero) (`cs.hero`).

<p align="center"><img src="Documentation/lettermemory.gif" width="380" alt="LetterMemory — a 4×4 board of face-down cards; flipping reveals letters and pictures, matching a letter to the picture that starts with it" /></p>

## Play

Open the project — `On Startup` deals the board. Tap two cards to turn them over:

- a **letter/syllable** card and a **picture** card match when they belong to the same word
  (e.g. **L** ↔ 🦁 *lion*, or in syllable mode **che** ↔ 🐴 *cheval*, **mo** ↔ 🏍️ *moto*);
- matched cards stay up, a mismatch turns back — find all eight pairs.
- **Lettre / Syllabe** switches between a first letter and the word's first reading syllable;
  **🇫🇷 / 🇬🇧** changes the pictures' names (and so the letters/syllables); **↻ Recommencer** re-deals.

## How it's built

Straight from [Memory4D](https://github.com/mesopelagique/Memory4D): the flip is a matched-geometry
move by hand — the back squishes to a zero-width sliver, the face takes its place and opens out,
two chained `cs.hero` tweens on one rectangle (`easeInQuad` closes, `easeOutQuad` opens). The
twist here is the deck: a pair is a letter card and a picture card sharing a pair id, so a turn
matches when the two ids agree — one letter meeting one picture, never two identical cards. The
pictures are dealt with distinct starting letters so each letter has exactly one answer.

## `cs.LetterMemory`

| Function | Action |
|:-|:-|
| `.reset()` | Deal eight letter/picture pairs with distinct letters, shuffled face-down. |
| `.pick($k)` | Flip card `$k` (0-based); the second flip resolves the turn. |
| `.selectLang($i)` | Language — `1` = Français, else English (re-deals with new names). |
| `.selectMode($i)` | Mode — `1` = Lettre (A), else Syllabe (ba, che, mo…); re-deals. |
