# Шаг 2. Enums `LineColor` и `TileFit` в Bozo

**Цель.** Добавить в `Bozo` перечисления цветов линий и типов «фита» —
единый источник для `HexTileData`, `BagData`, `BoardData`, `SandboxData`.

**Зависит от.** Шаг 1.

## Требования

- В `Bozo` добавить перечисление `LineColor` с **явными** числами:
  - `NONE = 0`, `RED = 10`, `BLUE = 11`, `GREEN = 12`, `YELLOW = 13`
- В `Bozo` добавить перечисление `TileFit` с **явными** числами:
  - `NONE = 0`, `ABC = 14` (три разных цвета), `ABA = 15`
    (два одинаковых через другой), `AAB = 16` (пара + третий; покрывает
    и `AAB`, и `ABB` — они эквивалентны с точностью до поворота).
- Оба enum зарегистрировать в `Type`, `type_to_index`, `type_to_enum`.
  Строковые ключи — в нижнем регистре: `red`, `blue`, `green`, `yellow`;
  `abc`, `aba`, `aab`.
- Использовать существующий `Type` (в шаге 1 там уже `ORDER=8, ASPECT=9`),
  добавить туда два новых значения: `LINE_COLOR = 17`, `TILE_FIT = 18`.
- Не заводить `TileKind`: в реальном наборе Tantrix 56 уникальных тайлов,
  группировать их по типу линий в data не нужно.
- Палитру, оставшуюся в `tantrix/tile/*` после шага 1 (константы `Color`
  для линий), перенести в `Digest.line_color_to_godot_color: Dictionary`
  (ключ — `Bozo.LineColor`, значение — `Color`). В `tile/` констант
  больше не держать. Рендер (`Cell`, `HandTile`) берёт цвет из `Digest`.

## Где использовать дальше

- `HexTileData.edge_colors: Array[int]` — 6 цветов (`Bozo.LineColor`).
- `Digest.hex_directions: Array[Vector2i]` — 6 направлений в axial.
- `Digest.tantrix_set: Array[Dictionary]` — таблица 56 стандартных тайлов.
- `Digest.line_color_to_godot_color: Dictionary` — enum → `Color` для рендера.
- `Advisor` (подсказки, шаги 7+) может возвращать `Bozo.TileFit` для
  визуализации выреза.

## Правила

Ссылки: `rules/bozo-enums.mdc`, `rules/gdscript-style.mdc`.

## Чек-лист

- [ ] В `Bozo` появился `LineColor` с `NONE = 0` и `RED = 10`…`YELLOW = 13`.
- [ ] В `Bozo` появился `TileFit` с `NONE = 0` и `ABC = 14`…`AAB = 16`.
- [ ] В `Type` добавлены `LINE_COLOR = 17`, `TILE_FIT = 18`.
- [ ] Значения не пересекаются с `Aspect = 1..4`, `Order = 5..7`,
      `Type = 8..9`.
- [ ] Оба enum зарегистрированы в `Type`, `type_to_index`, `type_to_enum`.
- [ ] `Bozo.enum_to_string(Bozo.Type.LINE_COLOR, Bozo.LineColor.RED) == "red"`.
- [ ] `Digest.line_color_to_godot_color` заполнен для всех 4 цветов.
- [ ] Константы `Color` в `tantrix/tile/*` заменены на `Digest`-таблицу,
      старых констант не осталось.
- [ ] Дублирующих enum в других файлах нет.