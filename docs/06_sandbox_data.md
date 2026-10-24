# Шаг 6. `SandboxData` и `Mother`

**Цель.** Корневая data песочницы: мешок, рука, доска, выбранный тайл.
`Mother` создаёт её в `_ready`. Игра бесконечная — сигналов окончания нет.

**Зависит от.** Шаги 4–5.

## `SandboxData` (`RefCounted`, корневой data песочницы)

- Создаётся в `Mother._ready`, живёт в `Mother.sandbox`.
- Поля:
  - `bag: BagData` — дочерняя data, регистрируется в `_init`.
  - `board: BoardData` — единственная доска.
  - `hand: Array[HexTileData]` — тайлы на руке (0..6).
  - `selected_hand_tile: HexTileData` — текущий выбранный тайл из руки,
    может быть `null`.
- Сигналы:
  - `hand_changed` — рука изменилась.
  - `board_changed` — доска изменилась.
  - `selection_changed` — выбранный тайл сменился.
  - `forced_spaces_changed` — пересчитались вырезы (для подсветки).
  - `bag_refilled` — мешок пополнился (для флейвора и `%BagLabel`).
- Никаких `is_endgame`, `endgame_started`, `game_finished` — игра
  не заканчивается.
- Методы:
  - `init_sandbox() -> void` — `bag.init(Catalog.BAG_SIZE)`,
    `board.init_empty()`, `hand = []`, `selected_hand_tile = null`,
    `draw_hand()`.
  - `draw_hand() -> void` — `while hand.size() < Catalog.HAND_SIZE:
    hand.append(bag.draw_random())`; эмитит `hand_changed`. Если
    `bag.refill_count` вырос — дополнительно `bag_refilled.emit()`.
  - `apply_selection(tile_data_: HexTileData) -> void` — установить/снять
    выбранный тайл; эмитит `selection_changed`.
  - `apply_rotation(delta_steps_: int) -> void` — повернуть выбранный
    тайл; эмитит `selection_changed`.
  - `apply_discard(tile_data_: HexTileData) -> void` — **sandbox
    extension**: убрать тайл из руки, добить руку через `draw_hand()`.
    Разрешает дедлок, когда ни один тайл не лезет по правилам.
    Эмитит `hand_changed` и `selection_changed`.
  - `can_place(tile_: HexTileData, cell_: Vector2i) -> bool` — полная
    проверка (шаг 9).
  - `apply_placement(tile_: HexTileData, cell_: Vector2i) -> bool` —
    положить, обновить `board`, убрать из `hand`, `draw_hand()`,
    эмитить сигналы.
  - `get_valid_cells_for(tile_: HexTileData) -> Array[Vector2i]` — все
    клетки, куда сейчас можно положить выбранный тайл.
  - `get_forced_spaces_with_fit() -> Array[Vector2i]` — вырезы, в
    которые у игрока есть подходящий тайл в руке.

## `Mother` (`global/mother.gd`)

- Добавить `sandbox: SandboxData`.
- `_ready`: `sandbox = SandboxData.new(); sandbox.init_sandbox()`.
- Поле `board` (корень после шага 1) заменить на `sandbox.board` во всех
  местах. Прямого `Mother.board` больше нет.

## Размещение в проекте

- `tantrix/sandbox/sandbox_data.gd` → `SandboxData`.
- `global/mother.gd` — расширить.
- Сцены у Sandbox нет.

## Правила

`rules/architecture.mdc`, `rules/feature-structure.mdc`,
`rules/gdscript-style.mdc`.

## Чек-лист

- [ ] `Mother.sandbox` создаётся в `_ready`.
- [ ] `BagData` — дочерняя data `SandboxData`, зарегистрирована в `_init`.
- [ ] `init_sandbox` раздаёт ровно `Catalog.HAND_SIZE` тайлов.
- [ ] `apply_selection`, `apply_rotation`, `apply_discard` эмитят
      `selection_changed` (и `hand_changed` где нужно).
- [ ] `Mother.board` удалён, все обращения идут через
      `Mother.sandbox.board`.
- [ ] В `notes.md`: `SandboxData` — единственный корень песочницы;
      игра не заканчивается; `apply_discard` — sandbox extension.
- [ ] Консоль без ошибок.