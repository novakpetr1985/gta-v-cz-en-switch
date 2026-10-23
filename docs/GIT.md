# GIT

Pravidla repozitáře a Git workflow.

## Větve

### Stálé větve

- `main` – stabilní a verzované vydání.
- `dev` – integrační větev probíhajícího vývoje.

### Vývojové větve

- `feature/*` – samostatně vyvíjené funkce nebo části projektu.
- `bugfix/*` – opravy chyb během vývoje.
- `refactor/*` – úpravy struktury nebo kódu bez změny funkce.

### Větve související s vydáním

- `release/*` – příprava nové verze před vydáním.
- `hotfix/*` – opravy chyb ve vydané verzi.

### Podpůrné větve

- `docs/*` – samostatné změny dokumentace.
- `build/*` – změny sestavení a distribuce.
- `ci/*` – změny CI/CD a automatizace.
- `chore/*` – údržba projektu a pomocné změny.

### Testovací a experimentální větve

- `test/*` – dočasné větve pro integrační testování připravených změn.
- `experiment/*` – experimentální nebo zkušební změny.

## Tok změn

```text
feature/*    → dev
bugfix/*     → dev
refactor/*   → dev
docs/*       → dev
build/*      → dev
ci/*         → dev
chore/*      → dev
test/*       → dev
experiment/* → dev

dev → release/vX.Y.Z → main → dev

hotfix/* → main → dev
```

Ostatní pracovní větve (`refactor/*`, `docs/*`, `build/*`, `ci/*`, `chore/*`) se stejně jako `feature/*` slučují do větve `dev`.

## Pull Request workflow

Změny určené k vydání se do větve `main` slučují prostřednictvím Pull Requestu.

### Pull Request do main

Vydání nové verze probíhá přes větev `release/vX.Y.Z`:

`release/vX.Y.Z` → `main`

Po úspěšném sloučení do `main` je vydána příslušná verze projektu.

### Pravidla Pull Requestu

- Změny se do `main` neslučují přímým commitem.
- Každé vydání je před sloučením kontrolováno a testováno.
- Pull Request musí mít jasný název a popis změn.
- Po úspěšném ověření lze Pull Request sloučit.

## Pravidla commitů

Zprávy commitů se zapisují vždy v angličtině. Komentáře ve zdrojových souborech, dokumentace a podrobné vysvětlení změn mohou být v češtině.

Doporučený formát používá stručný typ změny následovaný krátkým popisem:

```text
feat: add centralized color palette
hotfix: correct logger output
docs: update Git workflow
chore: update repository structure
refactor: simplify launcher logic
test: add launcher validation tests
build: update distribution package
ci: add automated checks
```

### Typy commitů

- `feat:` – nová funkce.
- `hotfix:` – oprava chyby.
- `docs:` – změny dokumentace.
- `refactor:` – úprava kódu bez změny funkce.
- `test:` – přidání nebo úprava testů.
- `build:` – změny sestavení a distribuce.
- `ci:` – změny CI/CD a automatizace.
- `chore:` – údržba projektu a pomocné změny.

## Verzování

Projekt používá verzování podle principů Semantic Versioning (SemVer).

Verze jsou označovány Git tagy ve formátu:

```text
vMAJOR.MINOR.PATCH
```

Příklady:

```text
v0.0.0
v0.1.0
v0.1.1
v1.0.0
```
