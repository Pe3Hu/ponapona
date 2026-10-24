# Шаг 4. Сущность `BagData` — бесконечный мешок

**Цель.** Мешок с тайлами, который никогда не заканчивается: когда
буфер пустеет, он тут же наполняется новым содержимым. `BagData` —
источник тайлов для руки; конец игры мешком не определяется.

**Зависит от.** Шаг 3.

## Дизайн

- В песочнице тайлы бесконечны. Фиксированного набора 56 нет.
- Буфер `remaining` можно посчитать («в мешке: N»), но он **всегда
  пополняется сразу**, как только опустеет. Игрок никогда не видит
  пустой мешок.
- `endgame` из правил Tantrix **не реализуется**: bag никогда не пуст,
  значит R1–R3 активны всегда. Это упрощение песочницы; отличие от
  настольной Tantrix зафиксировано в `notes.md`.

## Поля `BagData` (`RefCounted`)

- `remaining: Array[HexTileData]` — буфер тайлов. Игрок «видит» его
  как «в мешке: N».
- `refill_count: int` — сколько раз буфер пополнялся. Для флейвора
  и логов. Растёт в `_refill()`.

## Методы

- `init(bag_size_: int) -> void` — заполнить `remaining` через
  `_refill()`. После `init` `refill_count = 1` (начальное наполнение
  считается). Счётчик растёт при каждом `_refill`.
- `draw_random() -> HexTileData` — если `remaining.is_empty()`, вызвать
  `_refill()`; затем `Helper.rng.randi_range(0, remaining.size() - 1)`,
  вынуть и вернуть. Возвращает `null` **только** если `bag_size_ == 0`
  (неверная конфигурация; в норме не случается).
- `remaining_count() -> int` — `remaining.size()`.
- `is_empty() -> bool` — `remaining.is_empty()`. Нужен только для
  отладки; в игровом цикле не используется (всегда `false` после
  `draw_random`).
- `_refill() -> void` — `for i in Catalog.BAG_SIZE: remaining.append(_generate_tile())`;
  `refill_count += 1`.
- `_generate_tile() -> HexTileData` — сгенерировать один валидный
  Tantrix-тайл:
  - выбрать 3 разных цвета из 4 через `Helper.rng` (перестановка из
    `Catalog.LINE_COLOR_POOL`).
  - 6 рёбер: каждое ребро — часть пары; составить случайное
    разбиение `{0..5}` на 3 пары.
  - `edge_colors[i]` — цвет ребра `i` из перестановки.
  - `connections[i]` — парное ребро.
  - `origin = Vector2i.ZERO`, `rotation_steps = 0` (позицию и поворот
    задаст `SandboxData` при постановке).
  - ~~`variant_index = -1` — поля больше нет, шаг 4.~~
  - `is_valid()` должен возвращать `true`; если нет — залогировать и
    перегенерировать (защита от багнутого разбиения).

## Инвариант

`remaining.size() <= Catalog.BAG_SIZE` всегда. `draw_random` после
себя оставляет `remaining` непустым. `refill_count` монотонно растёт.

## Инициализация

- `BagData` создаётся в `SandboxData._init` (шаг 6).
- `init(Catalog.BAG_SIZE)` вызывается из `SandboxData.init_sandbox()`.
- Никаких `all_tiles`, `drawn`, `variant_index` — их нет.

## Размещение в проекте

- `tantrix/bag/bag_data.gd`.
- Сцены нет.

## Правила

`rules/architecture.mdc`, `rules/feature-structure.mdc`,
`rules/gdscript-style.mdc`.

## Чек-лист

- [ ] `BagData` создаётся только в `SandboxData._init`.
- [ ] `init(Catalog.BAG_SIZE)` заполняет `remaining`.
- [ ] `draw_random` никогда не возвращает `null` при `BAG_SIZE > 0`.
- [ ] Когда `remaining` опустел, `draw_random` сначала рефилит, потом
      выдаёт тайл.
- [ ] Сгенерированный тайл проходит `is_valid()`.
- [ ] Три разных цвета, 3 пары рёбер. ~~`variant_index = -1` снят: поля нет.~~
- [ ] Случайность — только `Helper.rng`.
- [ ] В `notes.md`: мешок бесконечный, размер буфера
      `Catalog.BAG_SIZE = 56`, `endgame` не реализуется.