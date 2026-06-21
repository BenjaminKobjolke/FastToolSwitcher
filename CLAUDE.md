# FastToolSwitcher — Project Instructions

AutoHotkey **v1.x** GUI app. Entry: `FastToolSwitcher.ahk`; logic in `lib/*.ahk`; config in `FastToolSwitcher.ini`.

## Coding Rules Source

Master rules live in: `D:\GIT\BenjaminKobjolke\claude-code\coding-rules`

Read on each rules update: `COMMON_RULES.md`, `AI_RULES.md`, `AUTOHOTKEY_RULES.md`.
Rules below are the project-relevant subset (single GUI app — multi-script-collection
AHK rules like the SingleInstance COM toggle, TrayMenu, `_libraries/` layout, per-script
auto-created ini, and setup/template scripts are intentionally omitted).

---

## AI Workflow Rules (always apply)

End-to-end workflow when planning and implementing changes. Each step is an existing
skill — run the skill, don't reimplement it.

**Feature / Change workflow** (after the user approves a plan):

```
plan approved
  → /plan:dry            check approved plan for DRY/consolidation BEFORE writing code
  → /plan:dry-checked    reload and review the DRY-adjusted plan
  → /convention:check    scan for existing patterns/components to reuse before implementing
  → implement
  → /dry:check           post-implementation DRY audit on changed files
  → /verify:after-change run tests + code analysis
```

- `/plan:dry` runs **before any code** — cheaper to remove duplication in the plan than the diff.
- `/convention:check` runs **before implementing** — reuse existing utilities/patterns.
- `/dry:check` + `/verify:after-change` run **after implementing**.

**Bug-fix workflow** (shorter, no plan-DRY phase):

```
bugs:fix → /verify:after-change
```

---

## Common Rules (project-relevant)

- **DRY.** No duplicated logic. Extract shared code into functions/modules; use constants for
  repeated values. (AHK form: extract into an `#Include`d helper rather than copy-paste.)
- **Derive, don't duplicate.** When one value strictly determines another, pass only the
  determinant and derive the rest — never thread both side-by-side into illegal combinations.
- **Use objects for related values.** When several related values travel together between
  functions/classes, bundle them into one config/settings object instead of long parameter lists.
- **Reuse existing models/structures** before inventing parallel data shapes. Search first.
- **String constants centralized.** No raw strings scattered across the codebase.
- **Prefer type-safe / explicit values** over stringly-typed magic where the language allows.
- **Max file length 300 lines.** Split a growing script into modules under `lib/` and `#Include`.
- **Naming.** Classes `PascalCase`; constants `UPPER_SNAKE_CASE`; descriptive function/label/
  hotkey-handler names (`MoveWindowTo`, not `mw`); be consistent within the project.
- **No god classes / one responsibility.** Split by responsibility; >5 public methods or
  unrelated domains in one unit is a warning sign.
- **Error handling & centralized logging.** Route diagnostics through one place with a single
  off switch; don't scatter ad-hoc output (see AHK logging note below).
- **Input validation at boundaries.** Validate external/user/file input; fail fast with clear messages.
- **Security baseline.** Never commit secrets (`.env`, keys, credentials); keep deps updated;
  validate/sanitize user input.
- **Confirm dependency versions** with the user before adding any new package/library.
- **README.md mandatory** in root: name/description, setup, usage, dependencies.
- **Reusable tooling.** Before building project-specific infra scripts, check the matching
  language `*_setup_files/` folder in the coding-rules repo for an existing equivalent.

**Exceptions for AutoHotkey** (per `AUTOHOTKEY_RULES.md`): the common **TDD**, **Integration
Tests**, and **Test Runner Scripts** (`run_tests.bat` / `run_integration_tests.bat`) rules do
**not** apply. Verify manually — run the app and confirm hotkeys/behavior work.

---

## AutoHotkey Rules (project-relevant, v1.x)

- **Standard script header** for predictable behavior:

  ```autohotkey
  #NoEnv                       ; performance/compatibility
  SendMode Input               ; faster, more reliable Send
  #Persistent                  ; keep running after the auto-execute section
  SetWorkingDir %A_ScriptDir%  ; relative paths resolve against the script
  ```

- **Reuse via `#Include`.** Shared logic goes in `lib/` and is pulled in with an
  `%A_ScriptDir%`-anchored include. Never copy-paste a helper between files — extract and include.

  ```autohotkey
  #Include %A_ScriptDir%\lib\WindowManager.ahk
  ```

- **Include order — function-only vs labels.** `#Include` injects text in place. A file with
  **bare top-level labels or executable statements** included *above* the auto-execute
  terminator (`return`/`ExitApp`) gets **fallen into at startup**. So: libs with callbacks
  expose them as **functions** (`Menu, ..., FuncName`, `OnExit("FuncName")`); a lib that must
  contain subroutine labels is `#Include`d at the **bottom**; function-only libs are safe anywhere.

- **Configuration over hardcoded paths.** No machine-specific paths/values baked into scripts —
  read them from the `.ini`. One place to change a value; portable by editing the ini only.

- **Logging.** Small scripts: `MsgBox` is fine for output/debugging. As a script grows, don't
  scatter `MsgBox` for tracing — route through a single logger gated by one `debug` flag, and
  reserve `MsgBox` for genuine user-facing prompts.

- **Manual verification.** No automated test suite for AHK — run the app, confirm hotkeys/behavior.

- **Do not launch the app yourself.** The AI must **never** start `FastToolSwitcher.ahk`
  (or any AutoHotkey exe) to test. After making changes, state clearly that **the user
  should test** by running the app, and list what to check. The user runs and verifies.
