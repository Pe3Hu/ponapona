# Шаг 5. Данные доски и сцены Board/Cell

**Цель.** Доска хранит положенные тайлы, вычисляет соседей и вырезы;
сцена показывает гекс-поле и линии тайлов.

**Зависит от.** Шаг 3.

## `CellData` (`RefCounted`)

- `coord: Vector2i` — axial-координаты клетки.
- `tile_data: HexTileData` — тайл на клетке, может быть `null`.

`CellData` не мутирует после создания. Смена тайла — замена в `BoardData`,
за ней пересборка клеток.

## `BoardData` (`RefCounted`)

- `tiles: Array[HexTileData]` — все положенные тайлы.
- `changed` — единый сигнал.

Методы:
- `init_empty() -> void` — пустая доска.
- `get_tile_at(cell_: Vector2i) -> HexTileData` — `null`, если пусто.
- `is_cell_free(cell_: Vector2i) -> bool`.
- `add_tile(tile_data_: HexTileData) -> void` — добавить (после
  валидации; валидация — в шаге 9).
- `update_tile(tile_data_: HexTileData) -> void` — заменить по `origin`.
- `clear_tiles() -> void`.
- `get_neighbor_tiles(cell_: Vector2i) -> Array` — 6 соседей (по
  `Digest.hex_directions`), только непустые, в порядке индексов рёбер
  0..5. Возвращает массив `[tile_or_null, …, tile_or_null]` длиной 6.
- `get_neighbor_tile_count(cell_: Vector2i) -> int` — сколько соседей
  занято.
- `get_forced_spaces() -> Array[Vector2i]` — все пустые клетки, у
  которых **ровно 3 соседа** и эти 3 соседа идут подряд (образуют V).
  Кэш пересобирается при `add_tile`/`update_tile`.
- `is_forced_space(cell_: Vector2i) -> bool` — `cell in get_forced_spaces()`.
- `get_controlled_cells() -> Array[Vector2i]` — клетки, примыкающие к
  вырезам по «открытой дуге» (см. шаг 10). Считается на лету.
- `get_first_tile() -> HexTileData` — первый тайл на доске (для
  стартовой позиции), `null`, если пусто.

## Сцена `Board`

- `tantrix/board/board.gd`, `board.tscn`.
- Единственный вход — сеттер `data: BoardData`.
- `connect_signals` → `_on_changed()`.
- `_on_changed()` пересобирает `Cell`-ы по `data.tiles` (плюс пустые
  клетки в радиусе 1 от любого тайла для визуала). Повторная сборка —
  `Helper.clear_children`.
- `@export is_interactive: bool` — в песочнице всегда `true`.
- `get_cell_at_global(pos: Vector2) -> Vector2i` — hit-test по гекс-сетке
  (обратное `hex_to_pixel`).
- `get_pixel_at_coord(coord: Vector2i) -> Vector2` — прямое
  преобразование.
- `highlight_cells(cells_: Array[Vector2i]) -> void` — поставить флаг
  подсветки соответствующим `Cell`. Вызывается из `Sandbox`
  (шаг 7), сама логика — в `Board`.
- `highlight_forced(cells_: Array[Vector2i]) -> void` — подсветка
  вырезов, куда у игрока есть подходящий тайл. Тоже из `Sandbox`.
- Логики валидации в сцене нет.

## Сцена `Cell`

- `tantrix/cell/cell.gd`, `cell.tscn`.
- Единственный вход — сеттер `data: CellData`.
- Рисует гекс; если `tile_data != null` — рисует цветные линии по
  `get_world_edge_color`. Цвет линии — из
  `Digest.line_color_to_godot_color`. Позиция —
  `Board.get_pixel_at_coord(coord)`.
- Флаг подсветки приходит от `Board` (сцена `Cell` не хранит своего
  состояния). Реализация — `Cell.highlight = true/false` или
  `modulate`.
- Логики в `Cell` нет, кроме рендера.

## Числа и таблицы

- `Catalog.HEX_SIZE: float` — размер гекса (если в проекте уже есть —
  использовать существующее имя, не дублировать).
- `Digest.hex_directions: Array[Vector2i]` — 6 направлений axial
  (если уже есть — использовать существующее).
- `Digest.tantrix_set: Array[Dictionary]` — 56 тайлов.
- `Digest.line_color_to_godot_color: Dictionary` — `Bozo.LineColor` → `Color`.
- `Helper.hex_to_pixel(coord_, size_) -> Vector2`,
  `Helper.pixel_to_hex(pos_, size_) -> Vector2i` — если уже есть в
  проекте, использовать существующее; если нет — добавить в `Helper`.

## Правила

`rules/architecture.mdc`, `rules/feature-structure.mdc`,
`rules/gdscript-style.mdc`, `rules/scene-and-data.mdc`.

## Чек-лист

- [ ] `CellData`, `BoardData` — `RefCounted`.
- [ ] `get_neighbor_tiles` возвращает ровно 6 слотов в порядке рёбер.
- [ ] `get_forced_spaces` считает только 3 подряд идущих соседа.
- [ ] `Board` рендерит клетки и тайлы, `Cell` показывает линии.
- [ ] `get_cell_at_global` работает на гекс-сетке.
- [ ] `highlight_cells` и `highlight_forced` реализованы.
- [ ] `Helper.hex_to_pixel` и `Helper.pixel_to_hex` согласованы
      (`pixel_to_hex(hex_to_pixel(c)) == c`).
- [ ] Консоль без ошибок.