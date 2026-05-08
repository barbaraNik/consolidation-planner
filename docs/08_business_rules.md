## Бизнес-правила консолидации

| ID | Правило | Проверяется в |
|---|---|---|
| BR-01 | Все заказы в одной консолидации должны иметь одинаковый destination_port. Смешение портов запрещено. | API /preview|
| BR-02 | Суммарный объём коробов всех заказов не должен превышать volume_m3 выбранного контейнера. | API /preview, /consolidations|
| BR-03 | Суммарный вес коробов всех заказов не должен превышать max_payload_kg выбранного контейнера. | API /preview, /consolidations|
| BR-04 | Заказ не может одновременно входить в две активные консолидации (calculation_status = 'ok'). При попытке будет выходить ошибка ORDER_ALREADY_CONSOLIDATED. | API /preview, /auto-select, /consolidations |
| BR-05 | Консолидация из 0 заказов не допускается. | API /preview, /consolidations |
