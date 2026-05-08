# Acceptance Criteria

| ID | Сценарий | Ожидаемый результат |
|---|---|---|
| AC-01 | GET /orders?port=CNSHA возвращает только заказы со статусом «Груз готов» и портом CNSHA. | HTTP 200, список заказов без нарушений. |
| AC-02 | GET /orders?port=CNSHA&exclude_consolidated=true не возвращает заказы, уже входящие в активную консолидацию. | Активный заказ отсутствует в ответе. |
| AC-03 | POST /preview с заказами из разных портов возвращает PORT_MISMATCH. | HTTP 400, код PORT_MISMATCH. |
| AC-04 | POST /preview с суммарным объёмом > volume_m3 контейнера возвращает VOLUME_EXCEEDED. | HTTP 200, status=violation, violations содержит VOLUME_EXCEEDED. |
| AC-05 | POST /preview с суммарным весом > max_payload_kg возвращает WEIGHT_EXCEEDED. | HTTP 200, status=violation, violations содержит WEIGHT_EXCEEDED. |
| AC-06 | POST /consolidations сохраняет запись в consolidations и связи в consolidation_orders. | HTTP 201, тело содержит consolidation_id; записи присутствуют в БД. |
| AC-07 | POST /consolidations с заказом, уже входящим в активную консолидацию, возвращает ошибку. | HTTP 409, код ORDER_ALREADY_CONSOLIDATED. |
| AC-08 | POST /consolidations с заказом в статусе отличном от «Груз готов» возвращает ошибку. | HTTP 400, код INVALID_STATUS. |
| AC-09 | GET /consolidations/{id} возвращает полный отчёт с вложенным списком заказов. | HTTP 200, поле orders содержит все заказы консолидации. |
| AC-10 | POST /consolidations/auto-select возвращает набор заказов, не нарушающих ограничения контейнера. | HTTP 200 |
| AC-11 | F-score рассчитывается корректно: F = 0.6·PV + 0.3·PM + 0.1·PN. | Значение f_score совпадает с расчётом по формуле |
| AC-12 | Все операции записи выполняются атомарно. При ошибке на любом шаге происходит полный откат. | В БД нет частично сохранённых записей. |
