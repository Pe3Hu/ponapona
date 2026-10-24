# Заметки шага 1. Ревизия

Статус: ревизия только. Код, сцены и `project.godot` не менялись.
Конспект снят с `.cursor/rules/*.mdc` — отдельной папки `rules/` в корне нет.

Главная сцена сейчас: `entities/world/world.tscn` (`uid://dv1mc17yeqcbq`).
Имя проекта в `project.godot`: `tantrix template`. Окно 1920×1080.
Автозагрузки: `Catalog`, `State`. `Mother`, `Helper`, `Bozo`, `Digest`, `Gear` отсутствуют.

Игрового цикла «рука из 6 тайлов» в проекте нет. Есть один `ShowcaseChunk`:
`Q`/`E` крутят его, ЛКМ по пустой клетке должен ставить копию. Постановка
через `legal_coords` сейчас сломана (см. ниже). Мешка, JSON-досок,
`tasks/`, `out/`, тестов нет.

---

## 1. Конспект `rules/*.mdc`

### Архитектура

Сцена (`Node` и наследники) показывает. `*Data` (`RefCounted`) хранит
состояние и считает правила. Сцена получает `data`, слушает сигналы,
рисует результат. Игровую логику в сцену не класть.

Корень состояния создаёт автозагрузка `Mother` в `_ready`. Читать его
только как `Mother.*`. Ноды по дереву как второй корень не использовать.

| Автозагрузка | Содержимое |
|---|---|
| `Mother` | корневые `*Data` |
| `Helper` | функции для разных сцен; `Helper.rng` |
| `Bozo` | все `enum` |
| `Digest` | справочники и таблицы соответствий |
| `Catalog` | статичные числа, массивы, размеры |
| `Gear` | длительности анимаций |

Автозагрузок ровно шесть. Новую не заводить.
`class_name` совпадает с файлом: `board.gd` — `Board`, `board_data.gd` — `BoardData`.

### Структура папок

Папка — фича. Рядом лежат `x.gd`, `x_data.gd`, `x.tscn`, картинки в
`images/`, шейдер рядом со скриптом, который его показывает.
Общих `scripts/`, `scenes/`, `datas/`, `components/` нет (в проекте
их и сейчас нет).

Вложенность повторяет владение: часть, нужная только родителю, —
его подпапка. Вариант со своей сценой получает свою папку. Вариант
только с data остаётся у родителя. Общее для нескольких фич
поднимается к ближайшему общему родителю. Проектное — в `global/`.
Файл в каждую фичу не копировать. Статичные дети сцены стоят в
`.tscn`, не создаются кодом.

Примеры в правиле (`entities/gobble`, `chain`) — из другого проекта.
Целевой корень этого шага задаёт `docs/01_refactor.md`: `tantrix/`
и `global/`. После переноса `entities/` не остаётся.

### Нейминг

- Файлы, функции, поля — `snake_case`. Классы — `PascalCase`.
  Скаляр в `Catalog` — `UPPER_SNAKE`. Массив и словарь — `snake_case`.
- Параметр заканчивается на `_`, тип указан, возвращаемый тип указан.
- `bool`-поле начинается с `is_`.
- Словарь называется по направлению: `aspect_to_color`.
- Коллекции типизированы.
- Чтение — `get_`. Изменение — `apply_`, `update_`, `refill_`, `recalc_`.
  Сборка — `init_`, `add_`.
- Сигнал — по событию (`amount_changed`). Обработчик — `_on_amount_changed`.
- Ранний выход в одну строку. Блок инициализации — `#region init`.
- Отступ — таб. Чужой код рядом не переформатировать.

### Сигналы и запись состояния

Состояние меняется через сеттер поля в `*Data`. Сеттер пишет значение
и шлёт сигнал. Сцена в `_on_*` только обновляет вид.
Дочерняя data в `_init` регистрируется у родителя. Сцена `*Data`
не конструирует. Корневые data создаёт только `Mother`.
Длительности — из `Gear`, числа — из `Catalog`, соответствия — из
`Digest`, случайность — из `Helper.rng`.

Ссылку на заранее известного ребёнка давать через `%UniqueName`
или `@export`. `get_node("путь/по/дереву")` не использовать.
`add_child` — только в `add_x` для элементов коллекции и для разовых
рантайм-объектов.

### Enum в Bozo

У каждого enum есть `NONE = 0`. Остальные значения продолжают общий
целочисленный ряд и между enum не повторяются. Следующее значение
на единицу больше текущего максимума.

Если имя нужно строкой, enum регистрируется в `Type`, `type_to_index`,
`type_to_enum`. Строку даёт `Bozo.enum_to_string`. Новое число — в
`Catalog`. Новая таблица «ключ → значение» — в `Digest`. В сцену
и в data их не копировать.

### Обязательный сеттер `data`

Единственный вход сцены — сеттер `data`:

```gdscript
var data: BoardData:
	set(value_):
		data = value_
		connect_datas()
		connect_signals()
		init_cells()
```

1. `connect_datas` раздаёт вложенные data уже стоящим в сцене нодам.
2. `connect_signals` подписывает `_on_*` и сразу вызывает каждый
   обработчик, чтобы картинка совпала с состоянием.
3. `init_xs` проходит коллекцию и зовёт `add_x`. Повторная сборка
   начинается с `Helper.clear_children`.

---

## 2. Карта «файл → ответственность → что делаем»

Общих `scripts/`, `scenes/`, `datas/`, `components/` нет.
`*Data` нет ни одного. Загрузчика `board_xxx.json` / `out/` нет.
`_unhandled_input` нет. Своего `RandomNumberGenerator` нет:
случайность идёт через глобальные `pick_random()` и `shuffle()`.

Input Map в `project.godot`: только экшен `click` (ЛКМ).
`Q` и `E` — сырые `KEY_Q` / `KEY_E` в `Cloth._input`.
`Escape` — `World._input`. Клик по клетке — `Notch._input` по экшену `click`.

| Файл | Ответственность | Что делаем |
|---|---|---|
| `global/State.gd` | enum `Order` (I/II/III) и `Aspect` (4 «цвета») | переименовать в `global/bozo.gd`, автозагрузка `Bozo` |
| `global/Catalog.gd` | числа гекса, таблицы направлений и цветов, 5 паттернов, расчёт mediums, соседние клетки | разрезать на `Catalog` / `Digest` / `Helper` |
| `entities/world/world.gd` + `world.tscn` | главная сцена, ESC, держит `Cloth` в `(968, 535)` | переименовать в `tantrix/sandbox/sandbox.*` |
| `entities/cloth/cloth.gd` + `cloth.tscn` | поле, постановка, легальность, витрина, `Q`/`E` | разрезать: поле → `board`, витрина и ввод → `sandbox`; состояние → `BoardData` |
| `entities/cloth/notch/notch.gd` + `notch.tscn` | пустая клетка, ховер, ЛКМ ставит тайл | переименовать в `tantrix/cell/cell.*`; `coord` вынести в `CellData` |
| `entities/cloth/chunk/chunk.gd` + `chunk.tscn` | гекс: паттерн, палитра, поворот, соседи, спавн линий | переименовать в `tantrix/tile/tile.*`; состояние → `TileData` |
| `entities/cloth/kink/kink.gd` + `kink.tscn` | линия связи двух рёбер (`Line2D`) | перенести в `tantrix/tile/kink/` |
| `entities/cloth/chunk/seam/seam.gd` + `seam.tscn` | маркер цвета на ребре | перенести в `tantrix/tile/seam/` |
| `entities/cloth/chunk/patterns/chunk_pattern.gd` | ресурс схемы связей: 6 `Order` по рёбрам | переименовать в `pattern.gd` / `Pattern` |
| `entities/cloth/chunk/patterns/{aabbcc,aabcbc,aabccb,abcabc,abcacb}.tres` | 5 топологий связей | перенести рядом с `Pattern`, поправить целые `Order` |
| `entities/cloth/chunk/palette/chunk_palette.gd` | случайная окраска трёх линков | переименовать в `palette.gd` / `Palette` |
| `entities/cloth/chunk/tilesets/m_merged.png` | атлас пустой/занятой клетки тайловой карты | в `tantrix/board/images/` |
| `entities/cloth/chunk/tilesets/tile_vertical.png` | подложка витрины | в `tantrix/sandbox/images/` |
| `entities/cloth/chunk/seam/images/sharp.png` | текстура шва | в `tantrix/tile/seam/images/` |
| `entities/cloth/chunk/seam/images/smooth.png` | текстура, ни одна сцена не ссылается | оставить на месте фичи seam |
| `shared/buttons/custom button.gd` | твин кнопки, в сценах не используется | не трогать |
| `shared/labels/defaul label.tres` | настройки лейбла, в сценах не используется | не трогать |
| `shared/fonts/*`, `shared/icon.svg` | шрифт проекта и иконка | не трогать |
| `project.godot` | главная сцена, автозагрузки, Input Map | обновить пути автозагрузок после переноса |

### Где что лежит сейчас

- Сцены: `world`, `cloth`, `chunk`, `notch`, `kink`, `seam`.
- Data: нигде. Состояние живёт в полях нод.
- `board_xxx.json`, `tasks/`, `out/`, `puzzles/`, `solutions/`: нет.
- `Q`/`E`: `entities/cloth/cloth.gd`, `_input`, ветки `KEY_Q` / `KEY_E`.
- ЛКМ: `entities/cloth/notch/notch.gd`, `_input`, экшен `click`.
- ESC: `entities/world/world.gd`, `_input`.
- Автозагрузки: `Catalog` (числа + таблицы + функции), `State` (enum).
- `Helper.rng`: нет. `Chunk.roll_kinks` → `Catalog.chunk_patterns.pick_random()`. `Palette.roll_aspects` → `Array.shuffle()`.
- Правила Tantrix: см. раздел 6.

---

## 3. Таблица «старое → новое»

Имена ниже — фактические. `hull`, `ingot`, `mold`, `warehouse`,
`forge`, `IngotPlacementData`, `is_flipped`, `PieceData` в репозитории
нет, создавать и «удалять» их не из чего.

| Сейчас | Станет | Действие |
|---|---|---|
| `global/State.gd` | `global/bozo.gd` | переименовать |
| числа в `global/Catalog.gd` | `global/catalog.gd` | оставить файл, сузить содержимое, имя в `snake_case` |
| таблицы из `Catalog` | `global/digest.gd` | вынести |
| функции соседей из `Catalog` | `global/helper.gd` | вынести, добавить `Helper.rng` |
| — | `global/mother.gd` | создать оболочку корня. Аналога нет, автозагрузка обязательна |
| — | `global/gear.gd` | создать пустую автозагрузку. Длительностей в игровом цикле нет |
| `entities/world/world.gd` | `tantrix/sandbox/sandbox.gd` | переименовать, `class_name Sandbox` |
| `entities/world/world.tscn` | `tantrix/sandbox/sandbox.tscn` | переименовать, uid сохранить |
| `entities/cloth/cloth.gd` | `tantrix/board/board.gd` | переименовать, `class_name Board` |
| `entities/cloth/cloth.tscn` | `tantrix/board/board.tscn` | переименовать, uid сохранить; витрину перенести в sandbox |
| состояние `Cloth` | `tantrix/board/board_data.gd` | вынести, `class_name BoardData` |
| `entities/cloth/notch/notch.gd` | `tantrix/cell/cell.gd` | переименовать, `class_name Cell` |
| `entities/cloth/notch/notch.tscn` | `tantrix/cell/cell.tscn` | переименовать |
| `coord` нотча | `tantrix/cell/cell_data.gd` | вынести, `class_name CellData` |
| `entities/cloth/chunk/chunk.gd` | `tantrix/tile/tile.gd` | переименовать, `class_name Tile` |
| `entities/cloth/chunk/chunk.tscn` | `tantrix/tile/tile.tscn` | переименовать |
| состояние чанка | `tantrix/tile/tile_data.gd` | вынести, `class_name TileData` |
| `entities/cloth/kink/*` | `tantrix/tile/kink/*` | перенести |
| `entities/cloth/chunk/seam/*` | `tantrix/tile/seam/*` | перенести |
| `chunk_pattern.gd` / `ChunkPatternResource` | `tantrix/tile/patterns/pattern.gd` / `Pattern` | переименовать |
| пять `*.tres` паттернов | `tantrix/tile/patterns/*.tres` | перенести, обновить целые под новый `Order` |
| `chunk_palette.gd` / `ChunkPaletteResource` | `tantrix/tile/palette/palette.gd` / `Palette` | переименовать |
| `m_merged.png` | `tantrix/board/images/m_merged.png` | перенести |
| `tile_vertical.png` | `tantrix/sandbox/images/tile_vertical.png` | перенести |
| `sharp.png`, `smooth.png` | `tantrix/tile/seam/images/` | перенести |
| `tasks/`, `out/`, `puzzles/`, `solutions/` | — | не создавать |
| `BagData`, `SandboxData`, `HandTile` | — | не создавать на шаге 1 |

Uid скриптов (файлы `*.gd.uid`) и uid сцен переезжают вместе с файлом.
Меняются пути в `ext_resource` и в автозагрузках. Копии по старому пути не оставлять.

### Корневое состояние

Сейчас корень — нода `Cloth`, её создаёт сцена. После шага 1 корень —
`Mother.board: BoardData`, создаётся в `Mother._ready`.
Шаг 6 обернёт `Mother.board` в `SandboxData` и переименует корень
в `Mother.sandbox`. Полей `hull` / `forge` / `weapons` нет.

`TileData` и `CellData` — дочерние. Их создаёт `BoardData`, не сцена.
Витринный тайл на шаге 1 тоже лежит в `BoardData`: отдельной руки нет,
а проверка цвета сравнивает витрину с соседями доски.

### Итоговая структура после шага 1

```text
global/
  mother.gd
  helper.gd
  bozo.gd
  digest.gd
  catalog.gd
  gear.gd
tantrix/
  sandbox/
    sandbox.gd
    sandbox.tscn
    images/tile_vertical.png
  board/
    board.gd
    board_data.gd
    board.tscn
    images/m_merged.png
  cell/
    cell.gd
    cell_data.gd
    cell.tscn
  tile/
    tile.gd
    hex_tile_data.gd
    tile.tscn
    kink/kink.gd
    kink/kink.tscn
    seam/seam.gd
    seam/seam.tscn
    seam/images/sharp.png
    seam/images/smooth.png
    patterns/pattern.gd
    patterns/aabbcc.tres
    patterns/aabcbc.tres
    patterns/aabccb.tres
    patterns/abcabc.tres
    patterns/abcacb.tres
    palette/palette.gd
shared/
  buttons/custom button.gd
  labels/defaul label.tres
  fonts/
  icon.svg
```

`entities/` после переноса пуст и удаляется.

### Куда что переезжает из `Catalog`

В `Catalog` остаются скаляры: `CHUNK_N`, `CHUNK_L`, `CHUNK_ANGLE`,
`MEDIUM_INSIDE_SCALE`, `MEDIUM_OUTSIDE_SCALE`, `CHUNK_SIZE`
(сейчас `CUNCK_SIZE`, нигде не читается; тот же `190×164` зашит в
`cloth.tscn`). `inside_mediums` нигде не читается — расчёт не переносить.
`outside_mediums` остаётся в `Catalog`: это геометрия из скаляров.

В `Digest`: `kink_orders`, `kink_aspects`, `direction_indexes`
(сейчас `direction_indexs`), `direction_differences`, `aspect_to_color`,
`chunk_patterns`. `aspect_to_string` заменяется на `Bozo.enum_to_string`.

В `Helper`: `get_neighbor_coord`, `get_reverse_direction_index`,
`get_direction_index`, `clear_children`, `rng`.
Имя `get_direction_index_based_on_direction` укорачивается при переносе.

Координаты на шаге 1 остаются offset (чётность `coord.x`, две таблицы
по 6 направлений). Обратное направление — `(index + 3) % 6`, таблицы
между собой согласованы. Позицию по-прежнему даёт `TileMapLayer.map_to_local`.
Axial и `Helper.hex_to_pixel` — шаг 5. На шаге 1 эту пару не переписывать:
тайловая карта и таблицы соседей должны остаться одним механизмом.

### Enum

Источник сейчас: `global/State.gd`. Явных чисел в файле нет, GDScript
нумерует с нуля в порядке объявления. `Aspect` в `.tres` не сериализован:
цвета живут в коде по именам `State.Aspect.*`. Сырые int паттернов —
это только `Order`.

`NONE = 0` обязателен → `Order` не может остаться `0/1/2`; выбрана схема
«больший enum занимает `1..n`, меньший уходит выше». `Order` — 3 значения,
`Aspect` — 4, поэтому низкие положительные числа забирает `Aspect`.
`NONE = 0` повторяется у каждого enum, остальные значения уникальны.

Других enum в `State` / `Bozo` нет (`Type` добавляется этим переносом,
не был четвёртым существующим). Других захардкоженных значений `Order`
в `.gd` / `.tscn` / `.tres` нет: пять паттернов ниже — единственное место
с сырыми `0/1/2`. `turns == 0` в `chunk.gd` — это поворот, не `Order`.
В `Bozo` каждое значение пишется явно (`I = 5`, не автопродолжение после
`NONE = 0`).

`Type` — реестр имён, не домен. Его ненулевые значения стоят после
`Order` и `Aspect`, иначе они заняли бы `1` и `2`.

Сейчас, `global/State.gd`:

| Enum | Сейчас |
|---|---|
| `Order` | `I = 0`, `II = 1`, `III = 2` |
| `Aspect` | `ENDURANCE = 0`, `STRENGTH = 1`, `AGILITY = 2`, `OBSERVATION = 3` |

Станет в `Bozo`. Числа `LineColor` = 10..13, `TileFit` = 14..16, `Type` расширен на 17..18. Следующее свободное значение — `19`.
Палитра переехала в `Digest`: `line_color_to_godot_color`.

| Enum | Станет |
|---|---|
| `Aspect` | `NONE = 0`, `ENDURANCE = 1`, `STRENGTH = 2`, `AGILITY = 3`, `OBSERVATION = 4` |
| `Order` | `NONE = 0`, `I = 5`, `II = 6`, `III = 7` |
| `Type` | `NONE = 0`, `ORDER = 8`, `ASPECT = 9` |

Соответствие старых int паттерна новым (`0 → 5`, `1 → 6`, `2 → 7`):

| Файл | Сейчас | Станет |
|---|---|---|
| `entities/cloth/chunk/patterns/aabbcc.tres` | `[0, 0, 1, 1, 2, 2]` | `[5, 5, 6, 6, 7, 7]` |
| `entities/cloth/chunk/patterns/aabcbc.tres` | `[0, 0, 1, 2, 1, 2]` | `[5, 5, 6, 7, 6, 7]` |
| `entities/cloth/chunk/patterns/aabccb.tres` | `[0, 0, 1, 2, 2, 1]` | `[5, 5, 6, 7, 7, 6]` |
| `entities/cloth/chunk/patterns/abcabc.tres` | `[0, 1, 2, 0, 1, 2]` | `[5, 6, 7, 5, 6, 7]` |
| `entities/cloth/chunk/patterns/abcacb.tres` | `[0, 1, 2, 0, 2, 1]` | `[5, 6, 7, 5, 7, 6]` |

Другие `.tres` числа `Order` не хранят. Пять паттернов и `global/bozo.gd`
изменены вместе: в `Bozo` у каждого значения явное число, без
автопродолжения после `NONE = 0`.

Автозагрузки не получают `class_name`: Godot 4.7 считает это
скрытием синглтона и не компилирует скрипт. Глобальное имя — имя
автозагрузки (`Bozo`, `Catalog`, …), файл в `snake_case`.

### Временное

`Aspect.STRENGTH` в прототипе — красный, `Aspect.OBSERVATION` — синий,
`Aspect.AGILITY` — зелёный, `Aspect.ENDURANCE` — жёлтый. Это исторический
выбор прототипа, не естественное соответствие имён и цветов.

`Digest.aspect_to_line_color` был временным мостом шага 2: `HexTileData`
ещё хранил `Aspect` вместо `LineColor`. На шаге 3 мост удалён.
`HexTileData.edge_colors` — `Array[int]` (`Bozo.LineColor`). `Aspect` в
контексте тайлов больше не используется и остаётся для игровых атрибутов
персонажа (`ENDURANCE` / `STRENGTH` / `AGILITY` / `OBSERVATION`).

`HexTileData` хранит `LineColor`, Aspect-мост удалён.

Шаг 2: визуализация расставленных на доске тайлов в `Cell` отсутствует.
Логика валидации работает. Рендер линий в `Cell` — шаг 5, в `HandTile` —
шаг 7. Это не баг, а известный разрыв между шагами. Узел `Tile`/`Kink`
по-прежнему рисует три линии и у витрины, и у тайла, уже стоящего на
доске; отдельной отрисовки клетки ещё нет.

Шаг 1–3: на витрине один тайл за раз. После расстановки витрина сразу
получает новый случайный тайл и не пустеет. Рука из 6 и добор из мешка —
шаги 6–8 (`BagData` + `SandboxData.hand`).

Генератор `_generate_tile` не исключает повтор `connections` подряд.
При необходимости — отдельная задача (дедуп на коротком горизонте).

Все 15 разбиений `{0..5}` на 3 пары допустимы как Tantrix-паттерны;
«3 corners» невозможно структурно. Генератор не может выдать
геометрически некорректный тайл.

`refill_count` после `init` = 1; счётчик считает наполнения, а не
рефилы после `init`.

`BoardData.roll_tile` — временный генератор витрины, используется
только шагами 1–4. После шага 6 (`SandboxData`) витрина берёт тайлы
из `hand`, а `roll_tile` удаляется на шаге 7 вместе с подключением
витрины к `selected_hand_tile`.

Тест V-вырезов на шаге 5 использовал искусственную позицию из 6 тайлов (без тайла в `(0,0)`). В живой сцене шага 5 `(0,0)` была занята первым тайлом. Тестовый скрипт удалён. С шага 6 доска стартует пустой: `(0,0)` — пустая клетка первого хода, витринный тайл лежит отдельно и сам на доску не кладётся.

`Cell` рисует линии от середины ребра к середине парного ребра по локальным `connections`, затем поворачивает узел линий на `rotation_steps`. `get_world_connection` для рисунка не вызывается.

`tile.gd` / `tile.tscn` с флагом `is_showcase` — мёртвый код после шага 7, удалён на шаге 8.

`cell.gd` в шаге 7 переведён в чистый рендер, кликов не ловит; ввод только в `Sandbox`.

`has_any_legal_move` вызывается из `_on_hand_changed`, `_on_selection_changed` и `_on_board_changed`, чтобы статус «Нет ходов — сбросьте тайл» появлялся сразу после добора и после хода.

Тест дедлока на шаге 8: четыре синих тайла вокруг выреза, рука из шести красных. `has_any_legal_move` был `false`, статус показал сброс. Хватило 1 `apply_discard`, после него легальный ход появился.

До шага 9 `get_valid_cells_for` на пустой доске возвращал только `[Vector2i.ZERO]`.

Шаги 6–8: `can_place` проверял пункты 1–4. Пункт 5 закрыт на шаге 9. Пункты 6–7 (R1–R3) остаются заглушками до шага 10.

На шаге 7 удалены `BoardData.roll_tile`, `BoardData.roll_showcase`, поле `showcase` и геттер `Mother.board`. Витрина — `HandTile` из `SandboxData.hand`. `apply_discard` привязан к правому клику по `HandTile`.

На шаге 9 `can_place` получил пункт 5: если `get_forced_spaces_with_fit` не пуст, ход разрешён только в эти клетки. Два соседних тайла вырез не создают (`forced` пуст: вырез — ровно 3 соседа подряд). Три тайла вокруг `(0,0)` дают `forced = [(0, 0)]`: подходящий тайл видит только эту клетку, неподходящий — ни одной.

`Catalog.FIRST_MOVE_RADIUS = 2`. Пустая доска: осевой диск радиуса 2, 19 клеток (1 + 6 + 12), `(0,0)` среди них. Первый ход в тесте встал в `(1, -2)`.

`tile_prev_variant` и `tile_next_variant` в Input Map нет. Поиск `variant_index`, `variant_change`, `tile_prev_variant`, `tile_next_variant`, `warehouse` в `*.gd` и `*.tscn` — 0 вхождений.

На шаге 10 R1 запрещает постановку, которая создаёт вырез с тремя одинаковыми цветами, в том числе когда игрок заполняет уже существующий вырез и этим создаёт соседний. R1–R3 активны всегда, эндгейма нет. R2 запрещает любого соседа выреза, R3 — только две контролируемые клетки открытой дуги; R3 ⊂ R2, оба проверяются отдельно. `apply_discard` закрывает дедлок от этих правил. В тесте хватило 1 сброса: вырез был closable, но R1 не пускал в него, после сброса подходящего тайла ход нашёлся снаружи.

Камера: WASD и перетаскивание средней кнопкой. Колесо зумит к курсору, шаг 0.1, диапазон 0.4–2.0. Home возвращает камеру в `(0,0)` и zoom 1. Скорость сдвига — `Catalog.CAMERA_PAN_SPEED` = 800 пикселей в секунду. Границ нет. Доска стоит в `(0,0)`: прежний сдвиг `(968, 535)` был центром экрана без камеры. `class_name` камеры — `SandboxCamera`, потому что имя `Camera` занято движком.

`Board.position` фиксирован в `(0, 0)`. Клетки стоят в локальных координатах доски через `hex_to_pixel`. Доска не центрируется на тайле; сдвигать вид может только камера.

Золотое правило сверено с рёбрами рендера. `hex_directions` идут по часовой, как середины рёбер `Cell`: восток, юго-восток, юго-запад, запад, северо-запад, северо-восток. `(d + 3) % 6` по-прежнему противоположное ребро. При rotation 0 несовпадение цвета даёт `can_place` = false, совпадение — true. Вращение в `get_world_edge_color` и поворот линий на `rotation_steps * 60°` идут в одну сторону.

`apply_auto_place` — sandbox extension, не правило Tantrix. Пробел генерирует новый тайл через `BagData.generate_one()`, рука не тратится. Сначала клетки с 3 соседями, потом с 2, потом с 1; 4 и больше пропускаются. Внутри одной группы порядок мешает `Helper.shuffle` (`Helper.rng`). `Catalog.AUTO_PLACE_ATTEMPTS` = 200: если тайл под фиксированные рёбра не собрался, клетка пропускается. Пустая доска даёт только `(0,0)`.

## Дубликаты и временное

- `BoardData.roll_tile` и `BagData._generate_tile` — дубликат; `roll_tile` удаляется на шаге 7.
- `BagData.init(0)` — защита от неверной конфигурации, не рабочее состояние.

`Helper.hex_to_pixel` и `Helper.pixel_to_hex` добавлены на шаге 5. Размер гекса — `Catalog.CHUNK_L` (отдельный `HEX_SIZE` не заводился). `pixel_to_hex(hex_to_pixel(c)) == c`. Соседи доски — осевые `Digest.hex_directions`.

`BoardData.get_forced_spaces` и `get_controlled_cells` — базовая реализация шага 5: вырез это ровно 3 подряд идущих соседа, контролируемые клетки — два края открытой дуги. Полные R1–R3 — шаг 10.

### Что выносится в data, поля пока прежние

`TileData` на шаге 1 называется `HexTileData` (`tantrix/tile/hex_tile_data.gd`).
В Godot 4.7 имя `TileData` занято нативным классом тайловой карты,
`class_name TileData` не компилируется. Сцена тайла по-прежнему `Tile`.

`TileData` на шаге 1 хранит то, что уже есть у `Chunk`: `pattern`,
`palette`, `turns`, `coord`, цвета линков. Поля `edge_colors`,
`connections`, `origin`, `rotation_steps`, `variant_index` — шаг 3. // variant_index появился на шаге 3, удалён на шаге 4 вместе с фиксированным набором 56
Переименовывать `turns` → `rotation_steps` на шаге 1 не нужно: это
уже смена модели, а не имени файла.

`CellData` на шаге 1: `coord`. Поле `tile_data` и слияние пустой клетки
с положенным тайлом — шаг 5. До тех пор пустая клетка — `Cell`,
положенный тайл — отдельная нода `Tile`.

`BoardData` на шаге 1: занятые координаты, внешние координаты,
легальные/нелегальные клетки, витринный `TileData`, список положенных
тайлов. Методы постановки и проверки цвета переезжают сюда из `Cloth`.

Сеттер `data` у `Board`, `Cell`, `Tile`: `connect_datas` →
`connect_signals` → `init_xs`, каждый `_on_*` вызывается сразу
после подписки.

---

## 4. Нарушения `rules/*.mdc`, которые чиним на шаге 1

- Состояние в сценах: `Cloth` (координаты, легальность, `coord_to_scene`),
  `Chunk` (паттерн, палитра, `turns`, соседи), `Notch` (`coord`).
- `*Data` создаются не из `Mother`, а из `_ready` сцены
  (`add_chunck(Vector2i.ZERO)`, `roll_kinks`).
- Сеттера `data` нет. Сигналов `*_changed` нет. Сеттеры `coord`,
  `aspect`, `direction_index` пишут поле и сразу рисуют.
- Enum лежат в `State`, без `NONE = 0`, без `Type`.
- `Catalog` смешивает числа, таблицы и функции. Имена `CUNCK_SIZE`,
  `direction_indexs`, `kink_orders` (без типа у нескольких const).
- Случайность через `pick_random` / `shuffle`, не через `Helper.rng`.
- `class_name` не совпадает с файлом: `ChunkPatternResource`,
  `ChunkPaletteResource`. Файлы автозагрузок в `PascalCase`.
- Параметры без `_` и без типа, пропущенные возвращаемые типы:
  `Cloth._input(event)`, `World._input(event)`, `Notch._input` без
  возврата, `Chunk.rotate_seams`, `Seam.custom_rotate`,
  `Catalog.init_mediums`, `Catalog.init_chunk_patterns`.
- Опечатки в рабочих именах: `add_chunck`, `ilegal_*`, `direcion_index_to_chunk`,
  `cloch` в `cloth.tscn` (у `Chunk` свойство называется `cloth`).
  `cloch` даёт предупреждение загрузки и не связывает витрину с полем.
  Витрина с `is_selected = true` поле почти не читает, поставленные
  тайлы получают `cloth` уже в `add_chunck`.
- `Chunk.refuse_seam` делает `direction_index_to_seam.erase(seam)` —
  ключ словаря это индекс ребра, не объект шва. Поправить при выносе.
- Успешная проверка цвета не записывает клетку в `legal_coords`
  (раздел 6). Починить на месте.

`get_node` по пути к соседу в коде нет: дети берутся через `%Notchs`,
`%Chunks`, `%ShowcaseChunk`. Этот кусок правила уже соблюдён.
Радиус клика `78` в `notch.tscn` и ширина линии `24` в `kink.tscn`
остаются в сцене как визуал. В логику они не входят.

---

## 5. Расхождения с доками `02`–`10`

Шаги `02`–`10` на шаге 1 не реализуются. Ниже — куда закрывать каждое
расхождение.

| Расхождение | Сейчас | Закрыть |
|---|---|---|
| Нет `LineColor` (`RED/BLUE/GREEN/YELLOW`). Цвет — `Aspect`: `STRENGTH` crimson, `OBSERVATION` blue, `AGILITY` green, `ENDURANCE` gold | `State.Aspect`, `Catalog.aspect_to_color` | **02.** Переименовать `Aspect` → `LineColor`, второй цветовой enum не заводить. Ключи строк станут `red` / `blue` / `green` / `yellow` |
| Числа из `docs/02_tantrix_enums.md` (`RED = 1`, `ABC = 1`) устарели | не учитывают общий ряд | **02.** Актуальные числа — таблица enum в этом файле. Шаг 2 заменит содержимое документа и продолжит ряд с `10` |
| Нет `TileFit` (`ABC` / `ABA` / `AAB`) | нет | **02.** Аналога нет, это новое |
| `TileData` не immutable и не имеет `edge_colors`, `connections`, `origin`, `rotation_steps`, `variant_index` | паттерн + палитра + `turns` + `coord` | **03.** `Order` и пять `.tres` после этого удалить: связь станет массивом `connections` // variant_index появился на шаге 3, удалён на шаге 4 вместе с фиксированным набором 56 |
| `get_world_edge_color` / `get_world_connection` / `is_valid` | цвет лежит на `Kink.aspect` и `Seam` | **03** |
| `is_flipped` | нет | не требуется |
| Нет набора из 56 тайлов. Генератор: 5 топологий × 3 разных цвета из 4 (один цвет всегда выкинут, повтор цвета на тайле невозможен) | `Palette.roll_aspects`, `Catalog.chunk_patterns` | **04.** `Digest.tantrix_set`, `BagData` |
| Нет `remaining` / `drawn`, возврата в мешок и нет | каждый ход витрина перебрасывается заново, колода бесконечная | **04**, раздача — **08** |
| `draw_random` через `Helper.rng` | `pick_random` / `shuffle` | текущие броски — шаг 1; колода — **04** |
| `CellData.tile_data`, пересборка клеток доски, `get_cell_at_global` | пустая клетка и тайл — разные ноды; хит-тест — `Area2D` нотча; позиция — `map_to_local` | **05** |
| `BoardData`: `get_neighbor_tiles` из 6 слотов, `get_forced_spaces`, `get_controlled_cells`, сигнал `changed` | списки координат на `Cloth`, соседи offset-таблицами | каркас соседей остаётся на шаге 1; API доски и axial — **05**; вырезы и контролируемые клетки — **10** |
| `Catalog.HEX_SIZE`, `Digest.hex_directions`, `Helper.hex_to_pixel` / `pixel_to_hex` | `CHUNK_L` / `CHUNK_SIZE`, `direction_differences`, `TileMapLayer` | **05** |
| `SandboxData`, `Mother.sandbox`, рука 0..6, `selected_hand_tile`, сигналы руки/выбора/эндгейма | один `ShowcaseChunk`, корень шага 1 — `Mother.board` | **06.** Обернёт `Mother.board` в `SandboxData` и переименует корень в `Mother.sandbox` |
| Сцена с `%Board`, `%Hand`, `%BagLabel`, `%StatusLabel`, `%HintLabel`, `HandTile` | `World` + `Cloth`, подписи нет, витрина — один тайл на спрайте `(-800, 0)` | **07** |
| Экшены `tile_rotate_left` / `tile_rotate_right`, клик по доске в `_unhandled_input` | сырые `KEY_Q`/`KEY_E`, `_input` на клетке | **07.** На шаге 1 `Q`/`E` остаются сырыми клавишами и продолжают крутить витрину |
| Свободная постановка первого тайла в любую клетку | `_ready` сам кладёт случайный тайл в `Vector2i.ZERO`. На шаге 1 это поведение сохраняется | **09** (`can_place`, п.3). Временное; шаг 9 заменит на свободный выбор клетки игроком. Добор руки до 6 — **08** |
| `can_place` из 6 пунктов, `apply_placement`, `get_valid_cells_for`, `get_forced_spaces_with_fit` | сравнение цвета витрины с соседом по общему ребру; при успехе клетка в список легальных не попадает | полный `can_place` — **09**. Дыру `legal_coords` закрыть на шаге 1 |
| Вырез = ровно 3 соседа подряд (V). Сейчас «вырез» в коде — это любая пустая соседняя клетка (`Notch`) | `update_external_coords` добавляет все 6 соседей | **10** |
| R1 три одинаковых цвета, R2 четвёртый сосед выреза, R3 контролируемая клетка | нет | **10** |
| Эндгейм снимает R1–R3, золотое правило остаётся. Конец игры при 56 тайлах на доске | партии не кончаются, ограничения не включаются | **08** (флаг и `game_finished`), **10** (снятие R1–R3) |
| Дедлок «Ход невозможен» и подсчёт петель в `%HintLabel` | нет | **10** |
| Загрузчик решений `tasks/` / `out/` | файлов нет | не требуется. Шаг 5 в части `tasks/` / `out/` не применяется |

Числа из `docs/02_tantrix_enums.md` устарели. Актуальный ряд — таблица
enum выше. Шаг 2 заменит содержимое того документа и продолжит ряд
с `10`.

---

## 6. Правила Tantrix в текущем коде

### Золотое правило — есть, успех не запоминается

`Cloth.check_seam_legal_based_on_coord_and_direction_index`: если сосед
уже занят, цвет шва витрины на этом ребре сравнивается с цветом
противоположного шва соседа (`reverse = index + 3`). Разные цвета —
клетка нелегальна. Пустое ребро цвет не ограничивает.

Это и есть совпадение цветов на общем ребре. Считается для одного
витринного тайла, не для произвольной руки.

Что сломано: `update_seams_based_on_coord` при полном совпадении не
вызывает `set_coord_as_legal`. В `legal_coords` клетка попадает только
обратным путём: сначала стать нелегальной, потом на следующем `Q`/`E`
переехать из `ilegal_coords`. Клетка, легальная с первого броска,
кликом не ставится. `Notch._input` ставит тайл только при
`legal_coords.has(coord)`.

Как починено: `BoardData.update_legality` заново собирает оба списка.
Клетка, у которой все шесть рёбер прошли без конфликта цвета, попадает
в `legal_coords`. Сравнение цветов на общем ребре не менялось: цвет
витрины на направлении `d` сверяется с цветом соседа на `d + 3`.
После постановки список пересчитывается сразу, иначе новая клетка
не становится кликабельной до следующего `Q`/`E`.

### Вырезы — не V

Пустые клетки — кольцо всех соседей занятых тайлов. Условия
«ровно три» и «три подряд» нет. Под это шаг 10.

### R1–R3 — нет

Четвёртого соседа, трёх одинаковых цветов на вырезе и контролируемых
клеток код не знает. Шаг 10. На шаге 1 методы-заглушки не добавлять.

### Эндгейм — нет

Мешок не пустеет, флага ограничений нет, партия не завершается.
Шаги 8 и 10.

### Рука и добор — нет

Один `ShowcaseChunk` (`is_selected = true`) на спрайте слева.
После постановки `reroll_showcase_chunk` собирает новый случайный
паттерн и новую палитру. Добора до 6 нет. Это шаги 6–8.

Решение шага 1: руку из шести не рисовать. Аналога нет, это новая
сущность документации 6–8. Рабочий цикл шага 1 — нынешний: доска,
одна витрина, `Q`/`E`, ЛКМ по легальной клетке.

### Первые ходы и камера

Сейчас `Cloth._ready` сам ставит случайный тайл в `Vector2i.ZERO`.
На шаге 1 это поведение сохраняется. Это временное: шаг 9 (`can_place`,
п.3) заменит его на свободный выбор клетки игроком. Шаг 8 — стартовая
раздача и добор, не свободная постановка.

Камеры нет. `World` ставит `Cloth` в `(968, 535)` при окне 1920×1080,
ноль доски около центра. Витрина — локально `(-800, 0)`.
На шаге 1 позицию не менять.

### `cloch`

В `entities/cloth/cloth.tscn` у `ShowcaseChunk` записано свойство
`cloch = NodePath("../..")`. У скрипта `Chunk` такого свойства нет,
экспорт называется `cloth`. Это опечатка, к карте переносов отношения
не имеет. Godot предупреждает о неизвестном свойстве, витрина через
него с полем не связывается. Поставленные тайлы получают `cloth`
уже в `add_chunck`.

Как починено: свойства `cloch` больше нет. Витрина стоит в
`sandbox.tscn` как `%Showcase` с существующим флагом `is_showcase`.
Поставленные тайлы создаёт `Board`, отдельной ссылки `cloth` у них нет.

---

## 7. `tasks/` и `out/`

Файлов `board_xxx.json`, каталогов `tasks/`, `out/`, `puzzles/`,
`solutions/`, загрузчика и тестов нет.

Загрузчик решений не требуется, шаг 5 в части `tasks/` / `out/` не
применяется. Соло-песочнице эти каталоги не нужны, на шаге 1 их не
создаём. В текущем `docs/05_board.md` раздела «Переименовать файлы»
и упоминаний `tasks/` / `out/` нет; ссылки на них есть в
`docs/01_refactor.md`, для этой песочницы они не применяются.

---

## 8. Удалить после подтверждения

Пока ничего не удалено.

Уйдут вместе с переносом, без второй копии:

- автозагрузка `State` и файл `global/State.gd`;
- каталог `entities/` после переноса файлов;
- расчёт и поле `inside_mediums` (нет читателей);
- словарь `aspect_to_string` (его место — `Bozo.enum_to_string`);
- свойство сцены `cloch`;
- мёртвый `Cloth.print_chunk_seams` и пустой `remove_connected_seams`;
- закомментированные куски легальности в `cloth.gd`, если при выносе
  в `BoardData` их нечего вызывать.

Не существуют, удалять нечего: `IngotPlacementData`, `is_flipped`,
`PieceData`, `Mother.hull`, `Mother.forge`, `Mother.weapons`,
второй `RandomNumberGenerator`.

`Order` на шаге 1 не удалять. Его снимет шаг 3, когда связь тайла
станет `connections`.

---

## 9. Сознательно не трогаем на шаге 1

- V-вырезы, R1–R3, эндгейм, набор из 56, axial-сетка. Шаги 02–10.
- `BagData`, `LineColor`, `TileFit`. Шаги 2 и 4.
- Рука из 6, `SandboxData`, `HandTile`. Шаги 6–8.
- `puzzles/`, `solutions/`, загрузчик решений.
- Свободную постановку первого тайла. На шаге 1 остаётся `_ready`:
  случайный тайл в `Vector2i.ZERO`. Замена — шаг 9.
- Input Map для `Q`/`E` и перевод клика в `_unhandled_input`. Шаг 7.
  Клавиши и экшен `click` остаются как есть.
- Позиция доски `(968, 535)` и витрина `(-800, 0)`.
- `shared/buttons/custom button.gd`. Пробел в имени, `class_name`
  `CustomTextureButton`, твин `0.1`. Ни одна сцена не ссылается.
  В `Gear` эту длительность не переносить.
- `shared/labels/defaul label.tres`, шрифты, `icon.svg`.
- `smooth.png` — не используется, лежит рядом с `sharp.png`.
- Рисование линий через `Kink` и `Seam`.
- Формулы кривой кинка и радиус `Area2D`.

Чек-лист шага 1 про «руку из 6» остаётся открытым до шагов 6–8.

---

## 10. Порядок после подтверждения

1. Автозагрузки: `Bozo` из `State`, разрез `Catalog`, пустые `Mother`
   и `Gear`, `Helper.rng`. Обновить все ссылки. Старый `State` убрать.
   Поправить пять `.tres`.
2. Перенос и переименование по таблице раздела 3. Обновить пути
   в сценах и `project.godot`. Старых файлов не оставлять.
   Витрину пересадить в сцену `Sandbox`, поле оставить `Board`.
3. Вынести `BoardData`, `TileData`, `CellData`. Сеттер `data`.
   Сцены перестают хранить правила. `Mother._ready` создаёт `board`.
   Случайность витрины и палитры — `Helper.rng`.
   Успешная проверка цвета пишет клетку в легальные.
4. Запуск главной сцены: доска видна, витрина из одного тайла видна,
   `Q`/`E` крутят её, ЛКМ ставит легальный ход, консоль без ошибок
   и предупреждений.

## Дизайн: бесконечная песочница

- Мешок бесконечный: буфер Catalog.BAG_SIZE = 56, при опустении
  тут же пополняется (`BagData._refill`). `endgame` из Tantrix
  не реализуется.
- Игра не заканчивается: `game_finished`, `is_endgame`,
  `endgame_started` не существуют. R1–R3 активны всегда.
- `apply_discard` — sandbox extension: игрок сбрасывает тайл из руки
  и добирает новый. Закрывает дедлок. В Tantrix такого правила нет.
- Поле растёт бесконечно; ограничений на размер доски нет.
- `variant_index` удалён на шаге 4; `hand.erase` сравнивает по ссылке.
- `SandboxData` — единственный корень песочницы, игра не заканчивается, `apply_discard` — sandbox extension. `Mother.board` — алиас `sandbox.board` до шага 7.
- `refill_count` — счётчик наполнений, не выдач. После N = BAG_SIZE выдач буфер пуст, refill_count = 1; рефил на выдаче N+1, refill_count = 2. Ленивый рефил.
- Шаг 9 — только правило вырезов (п.5 can_place) и радиус первого хода (Catalog.FIRST_MOVE_RADIUS = 2). R1–R3 — шаг 10. Смена варианта A/D не существует (variant_index удалён на шаге 4).