# Шаг 3. Сущность `HexTileData`

**Цель.** Тайл хранит цвета рёбер, схему соединений, позицию и поворот.

**Зависит от.** Шаг 2.

## Поля `HexTileData` (`RefCounted`)

- `edge_colors: Array[int]` — 6 цветов (`Bozo.LineColor`), индекс 0..5.
- `connections: Array[int]` — 6 значений, где `connections[i]` — ребро,
  соединённое линией с ребром `i`. Инвариант:
  `connections[connections[i]] == i`, `connections[i] != i`.
- `origin: Vector2i` — позиция на доске в axial-координатах.
- `rotation_steps: int` (0..5) — поворот на 60° за шаг.
- ~~`variant_index: int` — индекс тайла в стандартном наборе (0..55). Удалён на шаге 4: фиксированного набора нет.~~

## Методы

- `init_with_colors(edge_colors_, connections_, origin_ = Vector2i.ZERO,
  rotation_steps_ = 0) -> void` — единый конструктор.
  ~~Третий аргумент `variant_index_ = -1` удалён на шаге 4.~~
  **Immutable после `init_*`.**
- `get_world_edge_color(world_edge_: int) -> int` —
  `edge_colors[(world_edge_ - rotation_steps + 6) % 6]`.
- `get_world_connection(world_edge_: int) -> int` —
  `(connections[(world_edge_ - rotation_steps + 6) % 6] + rotation_steps) % 6`.
- `get_world_cells() -> Array[Vector2i]` — всегда `[origin]`.
- `is_valid() -> bool` — проверяет: `edge_colors.size() == 6`,
  `connections.size() == 6`, значения в диапазоне `Bozo.LineColor`,
  связи симметричны, `rotation_steps` в 0..5.

## Что не вводим

- `is_flipped` — тайлы Tantrix односторонние, отражение не применяется.
- Отдельный placement-класс — позиция живёт в `origin` самого тайла.

## Размещение в проекте

- `tantrix/tile/hex_tile_data.gd` → `HexTileData`.
- `tantrix/tile/tile.gd`, `tile.tscn` — сцена отображения (рисует гекс
  с линиями по `edge_colors` и `connections`, цвет берёт из
  `Digest.line_color_to_godot_color`).

## Правила

`rules/architecture.mdc`, `rules/feature-structure.mdc`,
`rules/gdscript-style.mdc`, `rules/scene-and-data.mdc`.

## Чек-лист

- [ ] `HexTileData` содержит `edge_colors`, `connections`, `origin`,
      `rotation_steps`. ~~`variant_index` удалён на шаге 4.~~
- [ ] `get_world_edge_color` корректен для rotation 0..5.
- [ ] `get_world_connection` корректен для rotation 0..5.
- [ ] `get_world_cells()` возвращает `[origin]`.
- [ ] `is_valid()` проверяет длину, диапазоны, симметрию связей.
- [ ] Консоль без ошибок.