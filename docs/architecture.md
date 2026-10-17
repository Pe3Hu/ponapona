# Раскладка по автозагрузкам

## Mother

`Mother.chain: ChainData` — корень состояния. Создаётся в
`_ready`. Читать как `Mother.chain`. Второй корень не создавать.

## Bozo

| Enum        | Значения                                       |
|-------------|------------------------------------------------|
| `Color`     | NONE, RED, YELLOW, GREEN, BLUE                 |
| `LinkShape` | NONE, CORNER, BEND, STRAIGHT                   |
| `Direction` | NONE, E, NE, NW, W, SW, SE                     |
| `Selection` | NONE, HOVER, PICKED                            |
| `Phase`     | NONE, NORMAL, ENDGAME, FINISHED                |
| `Result`    | NONE, WIN, LOSE                                |
| `CellKind`  | NONE, PILE, CHAIN                              |

У каждого `NONE = 0`. Остальные значения продолжают общий
целочисленный ряд.

`class_name` совпадает с файлом.

## Catalog

| Имя                    | Значение                    |
|------------------------|-----------------------------|
| `TILE_COUNT`           | 56                          |
| `EDGE_COUNT`           | 6                           |
| `LINK_COUNT`           | 3                           |
| `PLAYER_COLORS`        | [RED, YELLOW, GREEN, BLUE]  |
| `BOARD_RADIUS`         | 14                          |
| `POOL_SIZE`            | 6                           |
| `PILE_STEP`            | 2                           |
| `GOBBLE_MIN_SIZE`      | 3                           |
| `DOUBLE_GOBBLE_SIZE`   | 4                           |
| `HOLE_SIZE`            | 6                           |

## Digest

| Таблица                    | Ключ → Значение                     |
|----------------------------|-------------------------------------|
| `tile_id_to_links`         | int → Array[LinkData]               |
| `edge_pair_to_shape`       | Vector2i → LinkShape                |
| `direction_to_offset`      | int → Vector2i                      |
| `pile_neighbor_offsets`    | int → Vector2i (6 смещений)         |
| `pile_layout`              | Array[Vector2i] (56 позиций)        |
| `color_to_label`           | Color → String                      |

## Gear

| Имя             | Что                                    |
|-----------------|----------------------------------------|
| `place_tile`    | Появление тайла в цепи                 |
| `reveal_tile`   | Переворот тайла в куче                 |
| `phantom_fade`  | Появление/исчезновение фантома         |
| `phase_change`  | Смена фазы                             |
| `tempo`         | Базовый множитель                      |

## Helper

- `Helper.rng` — общий RNG.
- `Helper.clear_children` — очистка узла перед пересборкой.
- `Helper.hex_neighbors` — обход соседей по гекс-сетке.

## Data-дерево

```
ChainData
├── phase: Phase
├── result: Result
├── pile: PileData
│   ├── cell_to_cell: Dictionary[Vector2i, PileCellData]
│   ├── hidden_tiles: Array[TileData]
│   └── get_cell, reveal_random, move_to_chain
├── chain: ChainData
│   ├── cell_to_cell: Dictionary[Vector2i, ChainCellData]
│   ├── frontier: Array[Vector2i]
│   └── chain_size: int
├── pool: PoolData
│   └── coords: Array[Vector2i]
├── selection: SelectionData
│   ├── coord: Vector2i
│   ├── kind: Selection
│   └── rotation: int
├── hints: HintData
│   ├── enabled: bool
│   └── phantom_cells: Array[Vector2i]
├── gobbles: GobbleData
│   ├── coords: Array[Vector2i]
│   ├── forced_coords: Array[Vector2i]
│   ├── is_forced: bool
│   ├── closes_to_tile: Dictionary[Vector2i, Array[TileData]]
│   └── controlled_sides: Dictionary[Vector2i, Array[Vector2i]]
└── display: DisplayData
    ├── chain_size: int
    ├── loop_red: int
    ├── loop_yellow: int
    ├── loop_green: int
    ├── loop_blue: int
    ├── gobble_count: int
    ├── forced_hint: bool
    └── result: Result
```

Дочерние data в `_init` сами регистрируются у родителя.
Корневые data создаёт только `Mother`.

## Порядок пересчёта при `tile_placed`

1. `chain.recalc_frontier()`.
2. `gobbles.recalc()` — обход фронтира, отбор gobble.
3. `gobbles.recalc_controlled()` — блокированные клетки вдоль
   сторон незакрытых gobble.
4. `gobbles.recalc_forced(pool_)` — какие gobble закрываются
   видимым тайлом.
5. `phase.recalc()` — если `pile.is_empty_hidden()` →
   `ENDGAME`.
6. `display.recalc()`.
7. `hints.recalc()`.

## Сцены

```
ChainGame (Node2D)
├── PileField (Node2D)
│   └── PileCell (Node2D)
│       └── TileView
├── ChainField (Node2D)
│   └── ChainCell (Node2D)
│       └── TileView
├── GobbleLayer (Node2D)
│   └── GobbleMarker
├── PhantomLayer (Node2D)
│   └── Phantom
└── Hud (CanvasLayer)
    ├── ChainSize
    ├── LoopRed
    ├── LoopYellow
    ├── LoopGreen
    ├── LoopBlue
    ├── GobbleCount
    ├── PhaseLabel
    └── ResultScreen
```

## Фичи

- `entities/tile/` — тайл
- `entities/pile/` — куча (подрешётка)
- `entities/chain/` — цепь
- `entities/rules/` — проверки хода
- `entities/gobble/` — gobble, ограничения, подсветка
- `entities/phase/` — фаза и результат
- `entities/hints/` — выделение и фантомы
- `entities/input/` — клавиши и мышь
- `entities/display/` — подсчёт петель и HUD
- `entities/mode/chain/` — корневая сцена режима