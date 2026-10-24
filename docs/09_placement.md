# Шаг 9. Правило вырезов в can_place и радиус первого хода

**Цель.** Заменить стаб пункта 5 в `can_place` на реальное правило
вырезов. Расширить `get_valid_cells_for` на пустой доске до радиуса 2
вокруг `(0,0)`. Пункты 6–7 (R1–R3) остаются стабами до шага 10.

**Зависит от.** Шаги 3–8.

## Что уже реализовано (не трогать)

- `can_place` пункты 1–4: `tile != null`, клетка свободна, для непустой
  доски — есть сосед, золотое правило
  (`get_world_edge_color(d) == neighbor.get_world_edge_color((d + 3) % 6)`).
- `apply_placement`: копия через `init_with_colors`, `board.add_tile`,
  `hand.erase(tile_)`, `draw_hand`, `selected_hand_tile = null`,
  сигналы `board_changed`/`forced_spaces_changed`/`selection_changed`.
- `apply_selection`, `apply_rotation`, `apply_discard`,
  `get_forced_spaces_with_fit`, `has_any_legal_move`.

## Изменение 1: пункт 5 в can_place — правило вырезов

Между пунктом 4 и пунктом 6 (R1, стаб) добавить:

```gdscript
# 5. forced space priority: если есть closable forced spaces —
#    cell_ must be one of them
var forced := get_forced_spaces_with_fit()
if not forced.is_empty() and cell_ not in forced:
    return false
```

- `get_forced_spaces_with_fit()` возвращает **клетки-вырезы**, в которые
  у игрока есть подходящий тайл в руке.
- Смысл: если игрок **может** закрыть хотя бы один вырез — он обязан
  играть в вырез, свободные ходы запрещены. Правило Tantrix
  («Start your turn by filling every forced space that you can»).
- Тонкость: `can_place` вызывается с конкретным `tile_`. Если `tile_`
  не подходит ни под один closable вырез, но игрок выбрал его —
  `can_place` вернёт `false` и в вырезе (по золотому правилу цвет
  не сойдётся), и вне выреза (по пункту 5). Правильно: игрок должен
  выбрать в руке подходящий тайл.
- Пункт 5 не мешает первому ходу: на пустой доске вырезов нет,
  `get_forced_spaces_with_fit() == []`.

## Изменение 2: get_valid_cells_for — радиус первого хода

Сейчас на пустой доске возвращает `[Vector2i.ZERO]`. Изменить:

```gdscript
if board.tiles.is_empty():
    var cells: Array[Vector2i] = []
    for dx in range(-Catalog.FIRST_MOVE_RADIUS,
                    Catalog.FIRST_MOVE_RADIUS + 1):
        for dy in range(-Catalog.FIRST_MOVE_RADIUS,
                        Catalog.FIRST_MOVE_RADIUS + 1):
            # hex distance ограничивает квадрат до радиуса
            if abs(dx + dy) <= Catalog.FIRST_MOVE_RADIUS:
                cells.append(Vector2i(dx, dy))
    return cells
```

- `Catalog.FIRST_MOVE_RADIUS = 2`. Хекс-диск (не квадрат).
- Смысл: первый ход по правилам Tantrix — свободный, в любое место.
  Радиус 2 — компромисс, чтобы игрок не ставил за тридевять земель
  и камера не теряла тайл.
- **Осевой диск радиуса 2 = 1 + 6 + 12 = 19 клеток.** `(0,0)` входит.
  (Раньше в этом документе было ошибочно написано «13 клеток» —
  исправлено после шага 9; реализация верна.)

## Что НЕ входит в шаг 9

- R1 (три одинаковых цвета), R2 (четвёртый сосед), R3 (контролируемые
  клетки) — **шаг 10**. Пункты 6–7 в `can_place` остаются стабами
  `return true` с комментарием `# TODO step 10: R1-R3`.
- Смена варианта A/D — **не существует**. `variant_index` удалён
  на шаге 4, набор 56 снят. `tile_prev_variant`/`tile_next_variant`
  в Input Map не нужны.

## Что убрать из старой версии документа

- Раздел «Смена варианта (A/D)» с `variant_index`, `warehouse`,
  `tile_prev_variant`, `tile_next_variant` — целиком.
- Упоминания `warehouse.get_variant` — их в проекте нет.
- `TileData.variant_index` — удалён на шаге 4.

## Правила

`rules/architecture.mdc`, `rules/gdscript-style.mdc`,
`rules/scene-and-data.mdc`.

## Чек-лист

- [ ] В `can_place` между пунктом 4 и пунктом 6 добавлен пункт 5
      (правило вырезов).
- [ ] Пункт 5 не срабатывает на пустой доске (вырезов нет).
- [ ] Пункт 5 не срабатывает, если у игрока нет подходящего тайла
      в руке (`get_forced_spaces_with_fit() == []`).
- [ ] Пункт 5 блокирует свободный ход, если вырез closable.
- [ ] `get_valid_cells_for` на пустой доске возвращает
      `Catalog.FIRST_MOVE_RADIUS`-диск (19 клеток при радиусе 2).
- [ ] `Catalog.FIRST_MOVE_RADIUS = 2` добавлен.
- [ ] Пункты 6–7 остаются стабами с `# TODO step 10: R1-R3`.
- [ ] `tile_prev_variant`/`tile_next_variant` в Input Map отсутствуют
      (или удалены, если были).
- [ ] В `notes.md`: `variant_index`/`warehouse`/`tile_prev_variant`
      в шаге 9 не фигурируют; R1–R3 — шаг 10; радиус первого хода — 2,
      диск = 19 клеток.
- [ ] Консоль без ошибок.