# COLORS

## ANSI barevná paleta

Společná ANSI barevná paleta je definována v souboru [`colors.bat`](../core/colors.bat). Používají se světlé varianty barev pro tmavé pozadí.

## Barvy

- `BLUE` (94) – nadpisy kroků
- `CYAN` (96) – běžné informace
- `GREEN` (92) – úspěch
- `YELLOW` (93) – varování a upozornění
- `RED` (91) – chyba
- `GRAY` (90) – vedlejší údaje, čas, podrobnosti
- `WHITE` (97) – standardní světlý text a zvýraznění

## Formátovací atributy

- `BOLD` (1) – tučné zvýraznění
- `RESET` (0) – návrat na výchozí formátování

## Použití

Skripty používají společnou paletu načtením souboru [`colors.bat`](../core/colors.bat). Barvy slouží pouze k lepší čitelnosti výstupu a nemají ovlivňovat logiku skriptů.
