# Шаг 7. Сцена Sandbox

**Цель.** Показать доску, руку из 6 тайлов и статус (мешок, эндгейм).
Сцена только отображает; вся логика — в `SandboxData`.

**Зависит от.** Шаг 6.

## Сцена `Sandbox` (`tantrix/sandbox/sandbox.gd`, `sandbox.tscn`)

- Корневой `Control` (или `Node2D` — по правилам проекта).
- Дети:
  - `%Board: Board` — доска.
  - `%Hand: HBoxContainer` (или `GridContainer`) — контейнер под
    `HandTile`.
  - `%HandTileScene: PackedScene` — сцена тайла руки
    (`hand_tile.tscn`).
  - `%BagLabel: Label` — «В мешке: <N>».
  - `%StatusLabel: Label` — «Выберите тайл» / «Эндгейм» / «Готово» /
    «Ход невозможен».
  - `%HintLabel: Label` — подсказка по вырезам.
- Единственный вход — сеттер `data: SandboxData`:
  - `connect_datas`: `data.board → %Board.data`.
  - `connect_signals`: подписка на `data.hand_changed`,
    `data.board_changed`, `data.selection_changed`,
    `data.forced_spaces_changed`, `data.endgame_started`,
    `data.game_finished`; сразу вызывать обработчики.
  - `init_hand()` — собрать `HandTile`-ы.
- Обработчики:
  - `_on_hand_changed()` → пересобрать `%Hand` через
    `Helper.clear_children`, вызвать `add_hand_tile(tile_)` для каждого
    тайла из `data.hand`. Подсветить выбранный.
  - `_on_selection_changed()` → обновить подсветку тайлов в руке,
    обновить `%Board.highlight_cells(data.get_valid_cells_for(data.selected_hand_tile))`.
  - `_on_forced_spaces_changed()` →
    `%Board.highlight_forced(data.get_forced_spaces_with_fit())`,
    обновить `%HintLabel`.
  - `_on_endgame_started()` →
    `%StatusLabel.text = "Эндгейм: ограничения сняты"`.
  - `_on_game_finished()` → `%StatusLabel.text = "Готово"`.

## `HandTile` (сцена тайла в руке)

- `tantrix/sandbox/hand_tile.gd`, `hand_tile.tscn`.
- Единственный вход — сеттер `data: HexTileData`.
- Рисует гекс, как `Cell`, но с уменьшенным `Catalog.HEX_SIZE`.
- Нажатие ЛКМ эмитит `pressed(tile_data_)`.
- Подсветка выбранного — по флагу `is_selected`, ставится сценой
  Sandbox (не хранит состояние).

## Ввод

- ЛКМ по `HandTile` → `data.apply_selection(tile_)`. Повторный клик по
  тому же — `data.apply_selection(null)`.
- ЛКМ по `%Board` в `_unhandled_input`:
  `cell = %Board.get_cell_at_global(pos)`; если `data.selected_hand_tile`
  не `null` → `data.apply_placement(data.selected_hand_tile, cell)`.
  Если `apply_placement` вернул `false` —
  `%StatusLabel.text = "Нельзя"`.
- Клавиши `Q` / `E` — поворот выбранного тайла:
  `data.apply_rotation(-1)` / `(+1)`.
- Экшены `tile_rotate_left` (Q), `tile_rotate_right` (E) — добавить в
  Input Map, если их ещё нет.

## Правила

`rules/architecture.mdc`, `rules/feature-structure.mdc`,
`rules/gdscript-style.mdc`, `rules/scene-and-data.mdc`.

## Чек-лист

- [ ] Сцена `Sandbox` содержит `%Board`, `%Hand`, `%BagLabel`,
      `%StatusLabel`, `%HintLabel`.
- [ ] `connect_datas` раздаёт `data.board` в `%Board`.
- [ ] `_on_hand_changed` пересобирает `%Hand`.
- [ ] `_on_selection_changed` подсвечивает валидные клетки через
      `%Board.highlight_cells`.
- [ ] `_on_forced_spaces_changed` подсвечивает вырезы через
      `%Board.highlight_forced`.
- [ ] ЛКМ по `HandTile` выбирает тайл, повторный — снимает выбор.
- [ ] ЛКМ по `%Board` вызывает `data.apply_placement`.
- [ ] `Q`/`E` вызывают `data.apply_rotation`.
- [ ] Консоль без ошибок.