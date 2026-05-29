# Запрос на получение данных о всех заказах

| Атрибут | Значение |
|---|---|
| Назначение | Получить список заказов, доступных для включения в консолидацию. |
| HTTP Method | GET |
| Endpoint | /api/v1/orders |
| URL пример | api/v1/orders?search=q&port=CNSHA&status=Ready&supplier=name&exclude_consolidated=true&page=1&page_size=50 |

## Query Parameters

| Параметр | Тип | Обяз. | Описание |
|---|---|---|---|
| port | string | Да | Код порта назначения: CNSHA, CNTAO, CNTXG. |
| status | string | Нет | Фильтр по статусу. По умолчанию: «Ready». |
| exclude_consolidated | boolean | Нет | true — исключить заказы, входящие в активные консолидации. По умолчанию: true. |
| page | integer | Нет | Номер страницы (при отображении отсортированных заказов). По умолчанию: 1. |
| page_size | integer | Нет | Размер страницы. По умолчанию: 50. (при отображении отсортированных заказов показ на первой странице ограничивается 50 заказами) |

## Response Body

### 200 OK

```json
{
    "items": [
        {
            "order_id": 1,
            "order_number": "ORD-2025-008",
            "status_name": "Груз готов",
            "destination_port" : "CNSA",
            "planned_ship_date": "2026-06-13"
            "supplier_name": "Supplier-A", 
            "product_name": "string"
            "total_boxes": number
            "total_weight_kg": number
            "total_volume_m3": number
        }
    ],
    "currentPage"=1,
    "totalPage"=50,
    "pageSize"=50,
    "hasNextPage"=0
}

```

## Ошибки

| HTTP Code | Код ошибки | Описание | Текст ошибки |
|---|---|---|---|
| 400 | INVALID_PORT | Недопустимое значение параметра port | Возвращает на фронт при некорректно заданных query param `{"error": "Неверно указан {}"}`|
| 500 | INTERNAL_ERROR | Внутренняя ошибка сервера | Сервер недоступен `{"error": "Внутренняя ошибка сервера "}`|

## Бизнес-правила

- Если exclude_consolidated = true — исключаются заказы, присутствующие в consolidation_orders с активной консолидацией (calculation_status = 'ok').


---


# Запрос на получение данных о типах контейнеров

| Атрибут | Значение |
|---|---|
| Назначение | Получить справочник доступных типов контейнеров с характеристиками. |
| HTTP Method | GET |
| Endpoint | /api/v1/container-types |
| Query Parameters | - |

## Response Body

### 200 OK

```json
{
    "items": [
        {
         "container_type_id" : 1,
         "type_code": "40DC",
         "lenght_m" : 12.03,
         "width_m" : 2.35,
         "height_m" : 2.39,
         "max_paylod_kg" : 26300,
         "volumeM3": 67.7,
         "label": "40DC · 67.7 м³ · 26 300 кг"
        }
    ]
}
```

## Ошибки

| HTTP Code | Код ошибки | Описание | Текст ошибки |
|---|---|---|---|
| 500 | INTERNAL_ERROR | Внутренняя ошибка сервера | Сервер недоступен `{"error": "Внутренняя ошибка сервера "}`|

## Бизнес-правила

- Справочник статичен


---


# Запрос на формирование автоподбора заказов

| Атрибут | Значение |
|---|---|
| Назначение | Автоматически подобрать набор заказов, максимизирующий F-score в пределах ограничений контейнера.|
| HTTP Method | POST |
| Endpoint | /api/v1/consolidations/auto-select |

## Request Body

```json
{
  "container_type_id": 1,
  "destination_port": "CNSHA",
  "allowed_statuses": "Груз готов",
  "planned_ship_date": "2025-09-20"
}
```

## Response Body

### 200 OK

```json
{
  "selected_order": ["ORD-2025-008","ORD-2025-007"],
  "preview": {
      "total_weight_kg": 16450,
      "total_volume_m3": 37.325,
      "total_packages" : 12,
      "load_factor_volume": 0.5513,
      "load_factor_weight": 0.6255,
      "f_score": 0.6184
  },
  "calculation_status": "ok",
  
  "warnings": []
}
```

## Ошибки

| HTTP Code | Код ошибки | Описание | Текст ошибки |
|---|---|---|---|
| 400 | VALIDATION_ERROR | Отсутствует обязательное поле или недопустимое значение | Возвращает на фронт `{"error": "Поле {field} обязательно"}`|
| 404 | NO_ORDERS_FOUND | Нет заказов-кандидатов для данного порта | Возвращает на фронт при отсутствии данных, соответствующих заданным параметрам `{"error": "Нет заказов-кандидатов для данного порта"}` |
| 422 | INVALID_CONTAINER | Указанный container_type_id не существует | `{"error": "Указанный container_type_id не существует"}` |
| 500 | INTERNAL_ERROR | Внутренняя ошибка сервера | Сервер недоступен `{"error": "Внутренняя ошибка сервера "}`|

## Бизнес-правила

- Кандидаты - это заказы со статусом «Груз готов», port = указанный порт, также данный заказ не входит в активные консолидации.
- Алгоритм не должен превышать volume_m3 и max_payload_kg выбранного контейнера.


---


# Запрос на просчет выбранных контейнеров

| Атрибут | Значение |
|---|---|
| Назначение | Рассчитать метрики загрузки для выбранного набора заказов без сохранения в БД. |
| HTTP Method | POST |
| Endpoint | /api/v1/consolidations/preview |

## Request Body

```json
{
  "container_type_id": 1,
  "order_ids": [101, 105, 112]
}
```
## Response Body

### 200 OK
```json
{
  "container_type_id": 1,
  "container_code": "40DC",
  "total_volume_m3": 52.1,
  "total_weight_kg": 8900,
  "container_volume_m3": 67.7,
  "container_max_payload_kg": 26300,
  "load_factor_volume": 0.770,
  "load_factor_weight": 0.338,
  "load_factor_count": 0.600,
  "f_score": 0.623,
  "calculation_status": "ok",
  "violations": []
}
```
### Пример ответа при violation
```json
{
  "calculation_status": "violation",
  "violations": [
    { "type": "VOLUME_EXCEEDED", "value": 72.3, "limit": 67.7 },
    { "type": "WEIGHT_EXCEEDED", "value": 27100, "limit": 26300 }
  ]
}
```
## Ошибки

| HTTP Code | Код ошибки | Описание | Текст ошибки |
|---|---|---|---|
| 400 | INVALID_STATUS | Один или несколько заказов не имеют статуса «Груз готов» | Возвращает на фронт при некорректных статусах `{"error": "Среди выбранных заказов не все грузы имеют статус «Груз готов»"}` |
| 422 | INVALID_CONTAINER | Указанный container_type_id не существует | `{"error": "Указанный container_type_id не существует"}` |
| 500 | INTERNAL_ERROR | Внутренняя ошибка сервера | Сервер недоступен `{"error": "Внутренняя ошибка сервера "}`|


---


# Запрос на сохранение консолидации в БД: создать запись в consolidations и связь с заказов в consolidation orders

| Атрибут | Значение |
|---|---|
| Назначение | Сохранить консолидацию в БД: создать запись в consolidations и связи в consolidation_orders. |
| HTTP Method | POST |
| Endpoint | /api/v1/consolidations |

## Request Body

```json
{
  "container_type_id": 1,
  "order_ids": [101, 105, 112],
  "planned_ship_date": "2025-09-20",
  "comment": "Консолидация сформирована для букинга № х"
}
```
## Response Body

### 201 Created
```json
{
  "consolidation_id": 001,
  "destination_port": "CNSHA",
  "container_type_id": 1,
  "calculation_status": "ok",
  "load_factor_volume": 0.770,
  "load_factor_weight": 0.338,
  "f_score": 0.623,
  "total_volume_m3": 52.1,
  "total_weight_kg": 8900,
  "created_at": "2025-08-15T10:34:22Z"
}
```

## Ошибки

| HTTP Code | Код ошибки | Описание | Текст ошибки |
|---|---|---|---|
| 400 | VALIDATION_ERROR | Отсутствует обязательное поле или недопустимое значение | Возвращает на фронт `{"error": "Поле {field} обязательно"}`|
| 404 | NO_ORDERS_FOUND | Один или несколько order_ids не существуют в БД | Возвращает на фронт при отсутствии данных, соответствующих заданным параметрам `{"error": "Заказы не найдены: [101, 105]"}` |
| 500 | INTERNAL_ERROR | Внутренняя ошибка сервера | Сервер недоступен `{"error": "Внутренняя ошибка сервера "}`|

## Бизнес-правила

- Все проверки из /preview выполняются повторно внутри транзакции перед сохранением.
- При нарушении хотя бы одного бизнес-правила транзакция откатывается, возвращается 409 Conflict.
- При успехе возвращается 201 Created с заголовком Location: /api/v1/consolidations/{id}, например: Location: /api/v1/consolidations/001


---


# Запрос на получение данных в выгрузке консолидации

| Атрибут | Значение |
|---|---|
| Назначение | Получить полную информацию по сохранённой консолидации включая список заказов и метрики, что позволит отображать сформированные консолидации |
| HTTP Method | GET |
| Endpoint | /api/v1/consolidations/{consolidation_id} |
| Path Parameter | consolidation_id (integer) - идентификатор консолидации. |

## Response Body

### 200 OK

```json
{
  "consolidation_id": 77,
  "destination_port": "CNSHA",
  "container_type": {
    "type_code": "40DC",
    "volume_m3": 67.7,
    "max_payload_kg": 26300
  },
  "planned_ship_date": "2025-09-20",
  "calculation_status": "ok",
  "load_factor_volume": 0.770,
  "load_factor_weight": 0.338,
  "f_score": 0.623,
  "total_volume_m3": 52.1,
  "total_weight_kg": 8900,
  "created_at": "2025-08-15T10:34:22Z",
  "comment": "Оборудование по букингу № х",

  "orders": [
    {
      "order_id": 101,
      "order_number": "PO-2025-0042",
      "supplier_name": "Supplier_A",
      "total_boxes": 12,
      "volume_m3": 8.4,
      "weight_kg": 1250.0
    }
  ]
}
```
## Ошибки

| HTTP Code | Код ошибки | Описание | Текст ошибки |
|---|---|---|---|
| 404 | CONSOLIDATION_NOT_FOUND | Консолидация с указанным ID не найдена | Возвращает на фронт при отсутствии ID выбранной консолидации `{"error": "Консолидация с указанным ID не найдена"}` |
| 500 | INTERNAL_ERROR | Внутренняя ошибка сервера | Сервер недоступен `{"error": "Внутренняя ошибка сервера "}`|


---


# Запрос на выгрузку данных в формате PDF/Excel

| Атрибут | Значение |
|---|---|
| Назначение | Получить полную информацию по сохранённой консолидации в формате PDF/Excel |
| HTTP Method | GET |
| Endpoint | /api/v1/consolidations/{consolidation_id}/export?format=pdf /api/v1/consolidations/{consolidation_id}/export?format=xlsx |

## Response Body

### 200 OK

```json
{
  "consolidation_id": 77,
  "destination_port": "CNSHA",
  "container_type": {
    "type_code": "40DC",
    "volume_m3": 67.7,
    "max_payload_kg": 26300
  },
  "planned_ship_date": "2025-09-20",
  "load_factor_volume": 0.770,
  "load_factor_weight": 0.338,
  "f_score": 0.623,
  "total_volume_m3": 52.1,
  "total_weight_kg": 8900,
  "comment": "Оборудование по букингу № х",

  "orders": [
    {
      "order_id": 101,
      "order_number": "PO-2025-0042",
      "supplier_name": "Supplier_A",
      "total_boxes": 12,
      "volume_m3": 8.4,
      "weight_kg": 1250.0
    }
  ]
}
```
## Ошибки

| HTTP Code | Код ошибки | Описание | Текст ошибки |
|---|---|---|---|
| 400 | VALIDATION_ERROR | Отсутствует обязательное поле или недопустимое значение | Возвращает на фронт `{"error": "Поле {field} обязательно"}`|
| 500 | PDF_GENERATION_ERROR | Ошибка при создании PDF | `{"error": "Попробуйте другой формат или повторите позже"}` |
| 500 | EXCEL_GENERATION_ERROR | Ошибка при создании Excel | `{"error": "Попробуйте другой формат или повторите позже"}` |
