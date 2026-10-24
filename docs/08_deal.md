# Шаг 8. Стартовая раздача и рука (бесконечная)

**Цель.** Инициализировать бесконечный мешок, раздать `HAND_SIZE` тайлов,
обновлять руку после каждой расстановки. Игра не заканчивается.

**Зависит от.** Шаги 6–7.

## Стартовая раздача

- `SandboxData.init_sandbox()`:
  1. `bag = BagData.new(); bag.init(Catalog.BAG_SIZE)`.
  2. `board = BoardData.new(); board.init_empty()`.
  3. `hand = []; selected_hand_tile = null`.
  4. `draw_hand()`.

## Пополнение руки

- `SandboxData.draw_hand()`:
  - `while hand.size() < Catalog.HAND_SIZE: hand.append(bag.draw_random())`.
  - `bag.draw_random()` при пустом буфере сам вызывает `_refill()` —
    рука всегда добирается до `HAND_SIZE`.
  - Если во время добора `bag.refill_count` вырос — эмитить
    `bag_refilled` (для `%BagLabel` «мешок #N»).
  - Эмитить `hand_changed`.

## Сброс тайла (sandbox extension)

- `SandboxData.apply_discard(tile_data_: HexTileData) -> void`:
  - если `tile_data_` нет в `hand` — ранний выход;
  - `hand.erase(tile_data_)`;
  - `draw_hand()`;
  - если `selected_hand_tile == tile_data_` — `selected_hand_tile = null`,
    эмитить `selection_changed`.

## Дедлок

- Если ни один тайл из руки не проходит `can_place` — игрок в дедлоке.
  В песочнице это не конец игры, а сигнал «сбрось тайл». Сцена `Sandbox`
  показывает `%StatusLabel.text = "Нет ходов — сбросьте тайл"` и
  разрешает `apply_discard`.
- Спецсигнала `deadlock` не заводим: `Sandbox` проверяет
  `data.get_valid_cells_for(data.selected_hand_tile).is_empty()` и
  `data.has_any_legal_move()` при каждом `_on_*`.
- `SandboxData.has_any_legal_move() -> bool` — `true`, если существует
  тайл в руке и клетка на доске, для которых `can_place` возвращает
  `true`.

## Завершение игры

- **Игра не заканчивается.** `game_finished` не существует.
  Поле растёт, мешок пополняется, рука не уменьшается.

## Правила

`rules/architecture.mdc`, `rules/gdscript-style.mdc`,
`rules/scene-and-data.mdc`.

## Чек-лист

- [ ] `init_sandbox` раздаёт `Catalog.HAND_SIZE` тайлов.
- [ ] `draw_hand` не выдаёт больше `HAND_SIZE`; рука всегда добивается.
- [ ] При опустении буфера `draw_random` рефилит и выдаёт тайл —
      `null` не возвращается.
- [ ] `bag_refilled` эмитится, когда `refill_count` растёт.
- [ ] `apply_discard` убирает тайл из руки и добирает новый.
- [ ] `has_any_legal_move` возвращает корректный результат.
- [ ] `game_finished` не существует.
- [ ] В `notes.md`: игра бесконечная; дедлок обрабатывается
      `apply_discard`; `endgame` не реализуется.
- [ ] Консоль без ошибок.