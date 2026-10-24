# Шаг 11. Автопостановка (пробел) — sandbox extension

**Цель.** По нажатию пробела: найти самое требовательное пустое место
(максимум занятых соседей), сгенерировать подходящий под него тайл и
поставить. Если самое требовательное не заполнимо — перейти к
следующему по требовательности. Фича расширяет песочницу, в правилах
Tantrix её нет.

**Зависит от.** Шаги 3–10.

## Дизайн

- **Генерируется новый тайл, не из руки.** Рука не тратится. Это
  sandbox extension: в Tantrix нет «сгенерировать тайл».
- **Приоритет — самые требовательные клетки.** Сначала пробуем
  клетки с максимумом занятых соседей (вырезы = 3, потом 2, потом 1).
  Клетки с 4+ соседями пропускаются (R2 всё равно запретит).
- **Случайность — `Helper.rng`.** Среди клеток с одинаковой
  требовательностью выбор случайный; при генерации тайла — случайный
  перебор; при нескольких подходящих позициях — первая по требовательности.
- **Если ничего не подошло** — `%StatusLabel` = «Не могу поставить»,
  ход не делается.

## Новые методы

### `BagData.generate_one() -> HexTileData`

Публичная обёртка над `_generate_tile()`. Генерирует один валидный
тайл без затрагивания буфера `remaining`. Используется только
`SandboxData` для автопостановки.

### `SandboxData.find_demanding_cells() -> Array[Vector2i]`

Возвращает пустые клетки с ≥1 занятым соседом, отсортированные по
убыванию `get_neighbor_tile_count()`.

- Если `board.tiles.is_empty()` — `[Vector2i.ZERO]`.
- Клетки с `neighbor_count >= 4` в список не попадают.
- Внутри одной группы (одинаковый `neighbor_count`) — `Helper.rng`-перемешивание
  (`Array.shuffle()` через `Helper.rng`). Детерминизма по порядку нет.

### `SandboxData._generate_tile_for_cell(cell_: Vector2i) -> HexTileData`

Генерирует тайл, у которого фиксированные рёбра (где есть соседи)
имеют цвета этих соседей, обращённые к `cell_`.

```gdscript
func _generate_tile_for_cell(cell_: Vector2i) -> HexTileData:
    var fixed: Dictionary = {}  # d -> LineColor
    for d in range(6):
        var n := board.get_tile_at(cell_ + Digest.hex_directions[d])
        if n != null:
            fixed[d] = n.get_world_edge_color((d + 3) % 6)
    if fixed.size() > 3:
        return null  # R2 запретит, но защищаемся здесь
    for _i in range(Catalog.AUTO_PLACE_ATTEMPTS):
        var tile := bag.generate_one()
        var ok := true
        for d in fixed:
            if tile.edge_colors[d] != fixed[d]:
                ok = false
                break
        if ok:
            return tile
    return null
```

- `Catalog.AUTO_PLACE_ATTEMPTS = 200`. Если за 200 попыток не нашли —
  считаем, что под эту клетку тайла нет (например, вырез с 3
  одинаковыми цветами; в Tantrix-наборе такого тайла не существует).
- Не проверяет `can_place` — это делает вызывающий. Здесь только
  «подходит по фиксированным рёбрам».

### `SandboxData.apply_auto_place() -> bool`

```gdscript
func apply_auto_place() -> bool:
    var candidates := find_demanding_cells()
    for cell in candidates:
        var tile := _generate_tile_for_cell(cell)
        if tile == null:
            continue
        if apply_placement(tile, cell):
            return true
    return false
```

- Идёт по списку от самых требовательных к менее.
- Для каждой пытается сгенерировать тайл; если получилось и
  `apply_placement` не упал — успех, выходим.
- Если ни одна не подошла — `false`.

## Сцена `Sandbox`

- `_unhandled_input` на `KEY_SPACE` (или экшен `auto_place`):
  `data.apply_auto_place()`.
- `%StatusLabel`:
  - если `true` — «Авто: поставлено» (или координаты `(q,r)` для
    флейвора);
  - если `false` — «Не могу поставить».
- Input Map: добавить экшен `auto_place = Space`, если ещё нет.
  Использовать `is_action_just_pressed("auto_place")`, не сырой
  `KEY_SPACE` — по правилам проекта.

## Что НЕ входит

- `apply_auto_place` не тратит тайл из руки — рука остаётся 6
  (или столько, сколько было). Если рука была неполная (после
  discard) — `draw_hand` внутри `apply_placement` добьёт её до 6,
  это нормально.
- Не заменяет `apply_discard`. Discard остаётся для дедлока,
  auto_place — для «помоги мне поставить».

## Отличие от настольной Tantrix

- В Tantrix игрок сам выбирает тайл и место. «Сгенерировать тайл
  под вырез» — это читерство. В песочнице фича оправдана: игрок
  исследует игру, а не соревнуется.
- В `notes.md` явно: «`apply_auto_place` — sandbox extension,
  не правило Tantrix».

## Что записать в `notes.md`

- `apply_auto_place` — sandbox extension, не правило Tantrix.
- Генерируется новый тайл, рука не тратится.
- Приоритет — самые требовательные пустые клетки (3 соседа → 2 → 1).
- Клетки с 4+ соседями пропускаются (R2).
- `AUTO_PLACE_ATTEMPTS = 200`; если тайл не сгенерировался —
  клетка пропускается.
- Случайность — `Helper.rng`, детерминизма порядка нет.

## Правила

`rules/architecture.mdc`, `rules/gdscript-style.mdc`,
`rules/scene-and-data.mdc`.

## Чек-лист

- [ ] `BagData.generate_one()` — публичная обёртка над
      `_generate_tile()`, буфер не трогает.
- [ ] `SandboxData.find_demanding_cells()` — сортировка по убыванию
      `neighbor_count`, клетки с 4+ пропущены.
- [ ] `SandboxData._generate_tile_for_cell()` — перебор
      `AUTO_PLACE_ATTEMPTS`, проверка фиксированных рёбер.
- [ ] `SandboxData.apply_auto_place()` — идёт по списку, ставит
      первый подходящий.
- [ ] Пробел вызывает `apply_auto_place()`.
- [ ] `%StatusLabel` показывает результат.
- [ ] Input Map: `auto_place = Space`.
- [ ] Случайность — `Helper.rng`.
- [ ] В `notes.md` зафиксированы все решения из раздела
      «Что записать».
- [ ] Консоль без ошибок.