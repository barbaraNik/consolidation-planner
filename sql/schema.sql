--
-- PostgreSQL database dump
--

\restrict O5xjgOOYf1ZGKwkv0c37qU4Z6J7tekxaslLM3ILPMXxboRpayTetr5nYbYppyso

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: fn_log_order_status(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_log_order_status() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- срабатывает при INSERT (новый заказ) или при смене статуса
  IF (TG_OP = 'INSERT') OR (OLD.status_id <> NEW.status_id) THEN
    INSERT INTO public.order_status_history 
      (order_id, status_id, status_name, order_number, changed_at)
    VALUES 
      (NEW.order_id, NEW.status_id, NEW.status_name, NEW.order_number, NOW());
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_log_order_status() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: consolidation_orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.consolidation_orders (
    consolidation_id bigint NOT NULL,
    order_id bigint NOT NULL
);


ALTER TABLE public.consolidation_orders OWNER TO postgres;

--
-- Name: TABLE consolidation_orders; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.consolidation_orders IS 'consolidation_orders — таблица-мост, хранит только связи
consolidation_id — FK → ссылается на consolidations.consolidation_id
order_id — FK → ссылается на orders.order_id
Вместе они образуют составной PK: пара (consolidation_id, order_id) уникальна';


--
-- Name: consolidations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.consolidations (
    consolidation_id bigint NOT NULL,
    container_type_id bigint NOT NULL,
    destination_port character varying NOT NULL,
    planned_ship_date timestamp without time zone,
    calculation_status character varying,
    load_factor_volume numeric,
    load_factor_weight numeric,
    total_weight_kg numeric,
    total_volume_m3 numeric,
    f_score numeric,
    created_at timestamp without time zone,
    comment text
);


ALTER TABLE public.consolidations OWNER TO postgres;

--
-- Name: TABLE consolidations; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.consolidations IS 'consolidations — хранит сам сценарий загрузки контейнера
consolidation_id — PK (первичный ключ)
порт, дата, статус расчёта, метрики загрузки (PV, PM, F-score) и т.д.';


--
-- Name: container_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.container_types (
    container_type_id bigint NOT NULL,
    type_code character varying NOT NULL,
    length_m numeric NOT NULL,
    width_m numeric NOT NULL,
    height_m numeric NOT NULL,
    max_payload_kg numeric NOT NULL,
    volume_m3 numeric NOT NULL
);


ALTER TABLE public.container_types OWNER TO postgres;

--
-- Name: TABLE container_types; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.container_types IS 'Назначение: справочник типов морских контейнеров с их физическими характеристиками. Является нормативной основой для алгоритма консолидации: именно из этой таблицы берутся внутренние габариты (L, W, H) и допустимая грузоподъёмность (M), которые фигурируют в математической модели размещения грузов.';


--
-- Name: container_types_container_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.container_types ALTER COLUMN container_type_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.container_types_container_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: order_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_items (
    order_item_id bigint CONSTRAINT "order_items _order_item_id _not_null" NOT NULL,
    order_id bigint CONSTRAINT "order_items _order_id _not_null" NOT NULL,
    product_id bigint CONSTRAINT "order_items _product_id _not_null" NOT NULL,
    quantity integer CONSTRAINT "order_items _quantity _not_null" NOT NULL
);


ALTER TABLE public.order_items OWNER TO postgres;

--
-- Name: TABLE order_items; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.order_items IS 'Таблица предназначена для хранения товарных позиций внутри заказа';


--
-- Name: order_items _order_item_id _seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.order_items ALTER COLUMN order_item_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public."order_items _order_item_id _seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: order_status_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_status_history (
    history_id bigint NOT NULL,
    order_id bigint NOT NULL,
    status_id bigint NOT NULL,
    status_name text NOT NULL,
    changed_at timestamp without time zone NOT NULL,
    order_number character varying CONSTRAINT "order_status_history_order_number _not_null" NOT NULL
);


ALTER TABLE public.order_status_history OWNER TO postgres;

--
-- Name: TABLE order_status_history; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.order_status_history IS 'Таблица хранит изменение статусов заказа';


--
-- Name: order_status_history_history_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.order_status_history ALTER COLUMN history_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.order_status_history_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: order_statuses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_statuses (
    status_id bigint NOT NULL,
    status_name text NOT NULL
);


ALTER TABLE public.order_statuses OWNER TO postgres;

--
-- Name: TABLE order_statuses; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.order_statuses IS 'Таблица предназначена для хранения допустимых статусов заказа';


--
-- Name: order_statuses_status_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.order_statuses ALTER COLUMN status_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.order_statuses_status_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.orders (
    order_id bigint CONSTRAINT "orders _order_id _not_null" NOT NULL,
    order_number character varying CONSTRAINT "orders _order_number _not_null" NOT NULL,
    supplier_id bigint CONSTRAINT "orders _supplier_id_not_null" NOT NULL,
    status_id bigint CONSTRAINT "orders _status_id _not_null" NOT NULL,
    order_date timestamp without time zone,
    comment text,
    status_name text CONSTRAINT "orders _status_name_not_null" NOT NULL,
    supplier_name text CONSTRAINT "orders _supplier_name_not_null" NOT NULL,
    destination_port character varying NOT NULL,
    planned_ship_date timestamp without time zone
);


ALTER TABLE public.orders OWNER TO postgres;

--
-- Name: TABLE orders; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.orders IS 'Таблица предназначена для хранения общей информации о заказе
order_id — PK (первичный ключ)
номер заказа, поставщик, статус, порт назначения и т.д.';


--
-- Name: orders _order_id _seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.orders ALTER COLUMN order_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public."orders _order_id _seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: product_boxes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product_boxes (
    product_box_id bigint CONSTRAINT "product_boxes_product_box_id _not_null" NOT NULL,
    product_id bigint CONSTRAINT "product_boxes_product_id _not_null" NOT NULL,
    box_no integer CONSTRAINT "product_boxes_box_no _not_null" NOT NULL,
    length_m numeric(6,3) NOT NULL,
    width_m numeric(6,3) CONSTRAINT "product_boxes_width_m _not_null" NOT NULL,
    height_m numeric(6,3) CONSTRAINT "product_boxes_height_m _not_null" NOT NULL,
    weight_kg numeric(10,3) CONSTRAINT "product_boxes_weight_kg _not_null" NOT NULL,
    volume_m3 numeric(10,3) CONSTRAINT "product_boxes_volume_m3 _not_null" NOT NULL,
    can_tilt boolean NOT NULL,
    can_stack boolean NOT NULL
);


ALTER TABLE public.product_boxes OWNER TO postgres;

--
-- Name: TABLE product_boxes; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.product_boxes IS 'Таблица предназначена для хранения упаковочных характеристик товара';


--
-- Name: product_boxes_product_box_id _seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.product_boxes ALTER COLUMN product_box_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public."product_boxes_product_box_id _seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: products; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.products (
    product_id bigint CONSTRAINT "products _product_id _not_null" NOT NULL,
    product_name text CONSTRAINT "products _product_name _not_null" NOT NULL,
    sku character varying(13) CONSTRAINT "products _sku _not_null" NOT NULL,
    description text,
    is_active boolean CONSTRAINT "products _is_active _not_null" NOT NULL
);


ALTER TABLE public.products OWNER TO postgres;

--
-- Name: TABLE products; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.products IS 'Таблица предназначена для хранения справочника товаров';


--
-- Name: products _product_id _seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.products ALTER COLUMN product_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public."products _product_id _seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: suppliers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.suppliers (
    supplier_id bigint NOT NULL,
    supplier_name text NOT NULL,
    country text NOT NULL
);


ALTER TABLE public.suppliers OWNER TO postgres;

--
-- Name: TABLE suppliers; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.suppliers IS 'Таблица предназначена для хранения справочника поставщиков

supplier_id
supplier_name';


--
-- Name: suppliers_supplier_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.suppliers ALTER COLUMN supplier_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.suppliers_supplier_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: consolidation_orders consolidation_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.consolidation_orders
    ADD CONSTRAINT consolidation_orders_pkey PRIMARY KEY (consolidation_id, order_id);


--
-- Name: consolidations consolidations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.consolidations
    ADD CONSTRAINT consolidations_pkey PRIMARY KEY (consolidation_id);


--
-- Name: container_types container_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_types
    ADD CONSTRAINT container_types_pkey PRIMARY KEY (container_type_id);


--
-- Name: order_items order_items _pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT "order_items _pkey" PRIMARY KEY (order_item_id);


--
-- Name: order_status_history order_status_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_status_history
    ADD CONSTRAINT order_status_history_pkey PRIMARY KEY (history_id);


--
-- Name: order_statuses order_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_statuses
    ADD CONSTRAINT order_statuses_pkey PRIMARY KEY (status_id);


--
-- Name: orders orders _pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT "orders _pkey" PRIMARY KEY (order_id);


--
-- Name: product_boxes product_boxes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_boxes
    ADD CONSTRAINT product_boxes_pkey PRIMARY KEY (product_box_id);


--
-- Name: products products _pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT "products _pkey" PRIMARY KEY (product_id);


--
-- Name: suppliers suppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_pkey PRIMARY KEY (supplier_id);


--
-- Name: orders trg_order_status_history; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_order_status_history AFTER INSERT OR UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.fn_log_order_status();


--
-- Name: consolidation_orders consolidation_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.consolidation_orders
    ADD CONSTRAINT consolidation_id_fk FOREIGN KEY (consolidation_id) REFERENCES public.consolidations(consolidation_id) NOT VALID;


--
-- Name: consolidation_orders order_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.consolidation_orders
    ADD CONSTRAINT order_id_fk FOREIGN KEY (order_id) REFERENCES public.orders(order_id) NOT VALID;


--
-- Name: order_status_history order_status_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_status_history
    ADD CONSTRAINT order_status_fk FOREIGN KEY (order_id) REFERENCES public.orders(order_id) NOT VALID;


--
-- Name: order_status_history order_status_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_status_history
    ADD CONSTRAINT order_status_id_fk FOREIGN KEY (status_id) REFERENCES public.order_statuses(status_id) NOT VALID;


--
-- Name: orders order_statuses_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT order_statuses_fk FOREIGN KEY (status_id) REFERENCES public.order_statuses(status_id) NOT VALID;


--
-- Name: order_items orders_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT orders_fk FOREIGN KEY (order_id) REFERENCES public.orders(order_id) NOT VALID;


--
-- Name: order_items products_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT products_fk FOREIGN KEY (product_id) REFERENCES public.products(product_id) NOT VALID;


--
-- Name: product_boxes products_fk_box; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_boxes
    ADD CONSTRAINT products_fk_box FOREIGN KEY (product_id) REFERENCES public.products(product_id) NOT VALID;


--
-- Name: orders suppliers_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT suppliers_fk FOREIGN KEY (supplier_id) REFERENCES public.suppliers(supplier_id) NOT VALID;


--
-- PostgreSQL database dump complete
--

\unrestrict O5xjgOOYf1ZGKwkv0c37qU4Z6J7tekxaslLM3ILPMXxboRpayTetr5nYbYppyso

