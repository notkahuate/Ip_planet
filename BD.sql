--BASE DE DATOS--
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role_id UUID NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_users_role
        FOREIGN KEY (role_id)
        REFERENCES roles(id)
);

CREATE INDEX idx_users_role_id ON users(role_id);

CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(150) NOT NULL,
    sku VARCHAR(100) NOT NULL UNIQUE,
    category_id UUID NOT NULL,
    unit_price NUMERIC(18,2) NOT NULL CHECK (unit_price >= 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_items_category
        FOREIGN KEY (category_id)
        REFERENCES categories(id)
);

CREATE INDEX idx_items_category_id ON items(category_id);

CREATE TABLE warehouses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    location VARCHAR(200),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE movement_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) NOT NULL UNIQUE
);

INSERT INTO movement_types (name) VALUES
('ENTRY'),
('EXIT'),
('TRANSFER_IN'),
('TRANSFER_OUT');


CREATE TABLE item_warehouse_stock (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    item_id UUID NOT NULL,
    warehouse_id UUID NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_stock_item
        FOREIGN KEY (item_id)
        REFERENCES items(id),

    CONSTRAINT fk_stock_warehouse
        FOREIGN KEY (warehouse_id)
        REFERENCES warehouses(id),

    CONSTRAINT uq_item_warehouse UNIQUE (item_id, warehouse_id)
);

CREATE INDEX idx_stock_item_id ON item_warehouse_stock(item_id);
CREATE INDEX idx_stock_warehouse_id ON item_warehouse_stock(warehouse_id);

CREATE TABLE inventory_movements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    item_id UUID NOT NULL,
    warehouse_id UUID NOT NULL,
    movement_type_id UUID NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(18,2) NOT NULL CHECK (unit_price >= 0),
    reference_warehouse_id UUID NULL, -- usado para transferencias
    performed_by_user_id UUID NOT NULL,
    movement_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes TEXT,

    CONSTRAINT fk_movement_item
        FOREIGN KEY (item_id)
        REFERENCES items(id),

    CONSTRAINT fk_movement_warehouse
        FOREIGN KEY (warehouse_id)
        REFERENCES warehouses(id),

    CONSTRAINT fk_movement_type
        FOREIGN KEY (movement_type_id)
        REFERENCES movement_types(id),

    CONSTRAINT fk_movement_user
        FOREIGN KEY (performed_by_user_id)
        REFERENCES users(id),

    CONSTRAINT fk_reference_warehouse
        FOREIGN KEY (reference_warehouse_id)
        REFERENCES warehouses(id)
);

CREATE INDEX idx_movements_item_id ON inventory_movements(item_id);
CREATE INDEX idx_movements_warehouse_id ON inventory_movements(warehouse_id);
CREATE INDEX idx_movements_user_id ON inventory_movements(performed_by_user_id);
CREATE INDEX idx_movements_date ON inventory_movements(movement_date);

--Prodcedures y Functions Necesarias--



CREATE OR REPLACE PROCEDURE sp_register_inventory_entry(
    p_item_id UUID,
    p_warehouse_id UUID,
    p_quantity INTEGER,
    p_unit_price NUMERIC,
    p_user_id UUID,
    p_notes TEXT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_movement_type_id UUID;
    v_existing_stock INTEGER;
BEGIN

    -- Validaciones básicas
    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'Quantity must be greater than zero';
    END IF;

    IF p_unit_price < 0 THEN
        RAISE EXCEPTION 'Unit price cannot be negative';
    END IF;

    -- Obtener Movement Type ENTRY
    SELECT id INTO v_movement_type_id
    FROM movement_types
    WHERE name = 'ENTRY';

    IF v_movement_type_id IS NULL THEN
        RAISE EXCEPTION 'Movement type ENTRY not found';
    END IF;

    -- Verificar existencia de Item
    IF NOT EXISTS (SELECT 1 FROM items WHERE id = p_item_id AND is_active = TRUE) THEN
        RAISE EXCEPTION 'Item does not exist or is inactive';
    END IF;

    -- Verificar existencia de Warehouse
    IF NOT EXISTS (SELECT 1 FROM warehouses WHERE id = p_warehouse_id AND is_active = TRUE) THEN
        RAISE EXCEPTION 'Warehouse does not exist or is inactive';
    END IF;

    -- Verificar existencia de usuario
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = p_user_id AND is_active = TRUE) THEN
        RAISE EXCEPTION 'User not found or inactive';
    END IF;

    -- Iniciar bloque transaccional implícito
    -- (La procedure se ejecuta dentro de una transacción desde C#)

    -- Insertar movimiento
    INSERT INTO inventory_movements (
        item_id,
        warehouse_id,
        movement_type_id,
        quantity,
        unit_price,
        performed_by_user_id,
        notes
    )
    VALUES (
        p_item_id,
        p_warehouse_id,
        v_movement_type_id,
        p_quantity,
        p_unit_price,
        p_user_id,
        p_notes
    );

    -- Verificar si ya existe registro de stock
    SELECT quantity INTO v_existing_stock
    FROM item_warehouse_stock
    WHERE item_id = p_item_id
      AND warehouse_id = p_warehouse_id;

    IF NOT FOUND THEN
        -- Crear nuevo registro
        INSERT INTO item_warehouse_stock (
            item_id,
            warehouse_id,
            quantity
        )
        VALUES (
            p_item_id,
            p_warehouse_id,
            p_quantity
        );
    ELSE
        -- Actualizar stock existente
        UPDATE item_warehouse_stock
        SET quantity = quantity + p_quantity,
            updated_at = NOW()
        WHERE item_id = p_item_id
          AND warehouse_id = p_warehouse_id;
    END IF;

END;
$$;


CREATE OR REPLACE PROCEDURE sp_register_inventory_exit(
    p_item_id UUID,
    p_warehouse_id UUID,
    p_quantity INTEGER,
    p_unit_price NUMERIC,
    p_user_id UUID,
    p_notes TEXT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_movement_type_id UUID;
    v_current_stock INTEGER;
BEGIN

    -- Validaciones básicas
    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'Quantity must be greater than zero';
    END IF;

    IF p_unit_price < 0 THEN
        RAISE EXCEPTION 'Unit price cannot be negative';
    END IF;

    -- Obtener Movement Type EXIT
    SELECT id INTO v_movement_type_id
    FROM movement_types
    WHERE name = 'EXIT';

    IF v_movement_type_id IS NULL THEN
        RAISE EXCEPTION 'Movement type EXIT not found';
    END IF;

    -- Validar existencia de Item
    IF NOT EXISTS (SELECT 1 FROM items WHERE id = p_item_id AND is_active = TRUE) THEN
        RAISE EXCEPTION 'Item does not exist or is inactive';
    END IF;

    -- Validar existencia de Warehouse
    IF NOT EXISTS (SELECT 1 FROM warehouses WHERE id = p_warehouse_id AND is_active = TRUE) THEN
        RAISE EXCEPTION 'Warehouse does not exist or is inactive';
    END IF;

    -- Validar existencia de Usuario
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = p_user_id AND is_active = TRUE) THEN
        RAISE EXCEPTION 'User does not exist or is inactive';
    END IF;

    -- Obtener stock actual y bloquear fila (evita concurrencia)
    SELECT quantity INTO v_current_stock
    FROM item_warehouse_stock
    WHERE item_id = p_item_id
      AND warehouse_id = p_warehouse_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No stock record found for this item in this warehouse';
    END IF;

    -- Validar disponibilidad
    IF v_current_stock < p_quantity THEN
        RAISE EXCEPTION 'Insufficient stock. Available: %, Requested: %',
            v_current_stock, p_quantity;
    END IF;

    -- Insertar movimiento histórico
    INSERT INTO inventory_movements (
        item_id,
        warehouse_id,
        movement_type_id,
        quantity,
        unit_price,
        performed_by_user_id,
        notes
    )
    VALUES (
        p_item_id,
        p_warehouse_id,
        v_movement_type_id,
        p_quantity,
        p_unit_price,
        p_user_id,
        p_notes
    );

    -- Actualizar stock
    UPDATE item_warehouse_stock
    SET quantity = quantity - p_quantity,
        updated_at = NOW()
    WHERE item_id = p_item_id
      AND warehouse_id = p_warehouse_id;

END;
$$;

CREATE OR REPLACE PROCEDURE sp_transfer_inventory(
    p_item_id UUID,
    p_source_warehouse_id UUID,
    p_target_warehouse_id UUID,
    p_quantity INTEGER,
    p_unit_price NUMERIC,
    p_user_id UUID,
    p_notes TEXT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_transfer_out_id UUID;
    v_transfer_in_id UUID;
    v_source_stock INTEGER;
BEGIN

    -- Validaciones básicas
    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'Quantity must be greater than zero';
    END IF;

    IF p_source_warehouse_id = p_target_warehouse_id THEN
        RAISE EXCEPTION 'Source and target warehouse cannot be the same';
    END IF;

    -- Validar item
    IF NOT EXISTS (SELECT 1 FROM items WHERE id = p_item_id AND is_active = TRUE) THEN
        RAISE EXCEPTION 'Item does not exist or is inactive';
    END IF;

    -- Validar bodegas
    IF NOT EXISTS (SELECT 1 FROM warehouses WHERE id = p_source_warehouse_id AND is_active = TRUE) THEN
        RAISE EXCEPTION 'Source warehouse does not exist or is inactive';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM warehouses WHERE id = p_target_warehouse_id AND is_active = TRUE) THEN
        RAISE EXCEPTION 'Target warehouse does not exist or is inactive';
    END IF;

    -- Validar usuario
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = p_user_id AND is_active = TRUE) THEN
        RAISE EXCEPTION 'User does not exist or is inactive';
    END IF;

    -- Obtener tipos de movimiento
    SELECT id INTO v_transfer_out_id
    FROM movement_types
    WHERE name = 'TRANSFER_OUT';

    SELECT id INTO v_transfer_in_id
    FROM movement_types
    WHERE name = 'TRANSFER_IN';

    IF v_transfer_out_id IS NULL OR v_transfer_in_id IS NULL THEN
        RAISE EXCEPTION 'Transfer movement types not configured';
    END IF;

    -- 🔒 Bloquear stock origen
    SELECT quantity INTO v_source_stock
    FROM item_warehouse_stock
    WHERE item_id = p_item_id
      AND warehouse_id = p_source_warehouse_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No stock found in source warehouse';
    END IF;

    IF v_source_stock < p_quantity THEN
        RAISE EXCEPTION 'Insufficient stock in source warehouse. Available: %, Requested: %',
            v_source_stock, p_quantity;
    END IF;

    -- 🔒 Bloquear destino si existe
    PERFORM 1
    FROM item_warehouse_stock
    WHERE item_id = p_item_id
      AND warehouse_id = p_target_warehouse_id
    FOR UPDATE;

    -- Restar en origen
    UPDATE item_warehouse_stock
    SET quantity = quantity - p_quantity,
        updated_at = NOW()
    WHERE item_id = p_item_id
      AND warehouse_id = p_source_warehouse_id;

    -- Insertar o actualizar destino
    INSERT INTO item_warehouse_stock (item_id, warehouse_id, quantity)
    VALUES (p_item_id, p_target_warehouse_id, p_quantity)
    ON CONFLICT (item_id, warehouse_id)
    DO UPDATE
    SET quantity = item_warehouse_stock.quantity + EXCLUDED.quantity,
        updated_at = NOW();

    -- Insertar movimiento salida
    INSERT INTO inventory_movements (
        item_id,
        warehouse_id,
        movement_type_id,
        quantity,
        unit_price,
        reference_warehouse_id,
        performed_by_user_id,
        notes
    )
    VALUES (
        p_item_id,
        p_source_warehouse_id,
        v_transfer_out_id,
        p_quantity,
        p_unit_price,
        p_target_warehouse_id,
        p_user_id,
        p_notes
    );

    -- Insertar movimiento entrada
    INSERT INTO inventory_movements (
        item_id,
        warehouse_id,
        movement_type_id,
        quantity,
        unit_price,
        reference_warehouse_id,
        performed_by_user_id,
        notes
    )
    VALUES (
        p_item_id,
        p_target_warehouse_id,
        v_transfer_in_id,
        p_quantity,
        p_unit_price,
        p_source_warehouse_id,
        p_user_id,
        p_notes
    );

END;
$$;


CREATE OR REPLACE FUNCTION fn_get_inventory_status(
    p_item_id UUID DEFAULT NULL,
    p_warehouse_id UUID DEFAULT NULL
)
RETURNS TABLE (
    item_id UUID,
    item_name VARCHAR,
    warehouse_id UUID,
    warehouse_name VARCHAR,
    quantity INTEGER,
    unit_price NUMERIC,
    total_value NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        i.id,
        i.name,
        w.id,
        w.name,
        s.quantity,
        i.unit_price,
        (s.quantity * i.unit_price) AS total_value
    FROM item_warehouse_stock s
    JOIN items i ON s.item_id = i.id
    JOIN warehouses w ON s.warehouse_id = w.id
    WHERE (p_item_id IS NULL OR i.id = p_item_id)
      AND (p_warehouse_id IS NULL OR w.id = p_warehouse_id)
      AND i.is_active = TRUE
      AND w.is_active = TRUE;
END;
$$;


CREATE OR REPLACE FUNCTION fn_get_inventory_history(
    p_item_id UUID DEFAULT NULL,
    p_warehouse_id UUID DEFAULT NULL,
    p_user_id UUID DEFAULT NULL,
    p_start_date TIMESTAMPTZ DEFAULT NULL,
    p_end_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
    movement_id UUID,
    item_name VARCHAR,
    warehouse_name VARCHAR,
    movement_type VARCHAR,
    quantity INTEGER,
    unit_price NUMERIC,
    movement_date TIMESTAMPTZ,
    performed_by VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        m.id,
        i.name,
        w.name,
        mt.name,
        m.quantity,
        m.unit_price,
        m.movement_date,
        u.username
    FROM inventory_movements m
    JOIN items i ON m.item_id = i.id
    JOIN warehouses w ON m.warehouse_id = w.id
    JOIN movement_types mt ON m.movement_type_id = mt.id
    JOIN users u ON m.performed_by_user_id = u.id
    WHERE (p_item_id IS NULL OR m.item_id = p_item_id)
      AND (p_warehouse_id IS NULL OR m.warehouse_id = p_warehouse_id)
      AND (p_user_id IS NULL OR m.performed_by_user_id = p_user_id)
      AND (p_start_date IS NULL OR m.movement_date >= p_start_date)
      AND (p_end_date IS NULL OR m.movement_date <= p_end_date)
    ORDER BY m.movement_date DESC;
END;
$$;


CREATE OR REPLACE FUNCTION fn_get_inventory_report(
    p_start_date TIMESTAMPTZ DEFAULT NULL,
    p_end_date TIMESTAMPTZ DEFAULT NULL,
    p_warehouse_id UUID DEFAULT NULL,
    p_category_id UUID DEFAULT NULL
)
RETURNS TABLE (
    movement_date TIMESTAMPTZ,
    category_name VARCHAR,
    item_name VARCHAR,
    warehouse_name VARCHAR,
    movement_type VARCHAR,
    quantity INTEGER,
    unit_price NUMERIC,
    total NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        m.movement_date,
        c.name,
        i.name,
        w.name,
        mt.name,
        m.quantity,
        m.unit_price,
        (m.quantity * m.unit_price)
    FROM inventory_movements m
    JOIN items i ON m.item_id = i.id
    JOIN categories c ON i.category_id = c.id
    JOIN warehouses w ON m.warehouse_id = w.id
    JOIN movement_types mt ON m.movement_type_id = mt.id
    WHERE (p_start_date IS NULL OR m.movement_date >= p_start_date)
      AND (p_end_date IS NULL OR m.movement_date <= p_end_date)
      AND (p_warehouse_id IS NULL OR m.warehouse_id = p_warehouse_id)
      AND (p_category_id IS NULL OR i.category_id = p_category_id)
    ORDER BY m.movement_date DESC;
END;
$$;



CREATE OR REPLACE PROCEDURE sp_create_category(
    p_name VARCHAR,
    p_description TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN

    IF p_name IS NULL OR TRIM(p_name) = '' THEN
        RAISE EXCEPTION 'Category name cannot be empty';
    END IF;

    -- Validar duplicado
    IF EXISTS (
        SELECT 1 FROM categories 
        WHERE LOWER(name) = LOWER(p_name)
          AND is_active = TRUE
    ) THEN
        RAISE EXCEPTION 'Category with this name already exists';
    END IF;

    INSERT INTO categories (
        name,
        description
    )
    VALUES (
        TRIM(p_name),
        p_description
    );

END;
$$;


CREATE OR REPLACE PROCEDURE sp_update_category(
    p_id UUID,
    p_name VARCHAR,
    p_description TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN

    IF NOT EXISTS (
        SELECT 1 FROM categories 
        WHERE id = p_id AND is_active = TRUE
    ) THEN
        RAISE EXCEPTION 'Category not found';
    END IF;

    -- Validar duplicado en otro registro
    IF EXISTS (
        SELECT 1 FROM categories 
        WHERE LOWER(name) = LOWER(p_name)
          AND id <> p_id
          AND is_active = TRUE
    ) THEN
        RAISE EXCEPTION 'Another category with this name already exists';
    END IF;

    UPDATE categories
    SET name = TRIM(p_name),
        description = p_description
    WHERE id = p_id;

END;
$$;

CREATE OR REPLACE PROCEDURE sp_delete_category(
    p_id UUID
)
LANGUAGE plpgsql
AS $$
BEGIN

    IF NOT EXISTS (
        SELECT 1 FROM categories 
        WHERE id = p_id AND is_active = TRUE
    ) THEN
        RAISE EXCEPTION 'Category not found';
    END IF;

    -- Validar que no tenga items activos
    IF EXISTS (
        SELECT 1 FROM items
        WHERE category_id = p_id
          AND is_active = TRUE
    ) THEN
        RAISE EXCEPTION 'Cannot delete category with active items';
    END IF;

    UPDATE categories
    SET is_active = FALSE
    WHERE id = p_id;

END;
$$;


CREATE OR REPLACE FUNCTION fn_get_category_by_id(
    p_id UUID
)
RETURNS TABLE (
    id UUID,
    name VARCHAR,
    description TEXT,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.name,
        c.description,
        c.created_at
    FROM categories c
    WHERE c.id = p_id
      AND c.is_active = TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION fn_get_categories()
RETURNS TABLE (
    id UUID,
    name VARCHAR,
    description TEXT,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.name,
        c.description,
        c.created_at
    FROM categories c
    WHERE c.is_active = TRUE
    ORDER BY c.name;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_create_warehouse(
    p_name VARCHAR,
    p_location VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN

    IF p_name IS NULL OR TRIM(p_name) = '' THEN
        RAISE EXCEPTION 'Warehouse name cannot be empty';
    END IF;

    -- Validar duplicado
    IF EXISTS (
        SELECT 1 FROM warehouses
        WHERE LOWER(name) = LOWER(p_name)
          AND is_active = TRUE
    ) THEN
        RAISE EXCEPTION 'Warehouse with this name already exists';
    END IF;

    INSERT INTO warehouses (
        name,
        location
    )
    VALUES (
        TRIM(p_name),
        p_location
    );

END;
$$;

CREATE OR REPLACE PROCEDURE sp_update_warehouse(
    p_id UUID,
    p_name VARCHAR,
    p_location VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN

    IF NOT EXISTS (
        SELECT 1 FROM warehouses
        WHERE id = p_id AND is_active = TRUE
    ) THEN
        RAISE EXCEPTION 'Warehouse not found';
    END IF;

    -- Validar duplicado en otro registro
    IF EXISTS (
        SELECT 1 FROM warehouses
        WHERE LOWER(name) = LOWER(p_name)
          AND id <> p_id
          AND is_active = TRUE
    ) THEN
        RAISE EXCEPTION 'Another warehouse with this name already exists';
    END IF;

    UPDATE warehouses
    SET name = TRIM(p_name),
        location = p_location
    WHERE id = p_id;

END;
$$;

CREATE OR REPLACE PROCEDURE sp_delete_warehouse(
    p_id UUID
)
LANGUAGE plpgsql
AS $$
BEGIN

    IF NOT EXISTS (
        SELECT 1 FROM warehouses
        WHERE id = p_id AND is_active = TRUE
    ) THEN
        RAISE EXCEPTION 'Warehouse not found';
    END IF;

    -- Validar que no tenga stock
    IF EXISTS (
        SELECT 1 FROM item_warehouse_stock
        WHERE warehouse_id = p_id
          AND quantity > 0
    ) THEN
        RAISE EXCEPTION 'Cannot delete warehouse with existing stock';
    END IF;

    -- Validar que no tenga movimientos históricos
    IF EXISTS (
        SELECT 1 FROM inventory_movements
        WHERE warehouse_id = p_id
    ) THEN
        RAISE EXCEPTION 'Cannot delete warehouse with movement history';
    END IF;

    UPDATE warehouses
    SET is_active = FALSE
    WHERE id = p_id;

END;
$$;

CREATE OR REPLACE FUNCTION fn_get_warehouse_by_id(
    p_id UUID
)
RETURNS TABLE (
    id UUID,
    name VARCHAR,
    location VARCHAR,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        w.id,
        w.name,
        w.location,
        w.created_at
    FROM warehouses w
    WHERE w.id = p_id
      AND w.is_active = TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION fn_get_warehouses()
RETURNS TABLE (
    id UUID,
    name VARCHAR,
    location VARCHAR,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        w.id,
        w.name,
        w.location,
        w.created_at
    FROM warehouses w
    WHERE w.is_active = TRUE
    ORDER BY w.name;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_create_item(
    p_name VARCHAR,
    p_sku VARCHAR,
    p_category_id UUID,
    p_unit_price NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN

    IF p_name IS NULL OR TRIM(p_name) = '' THEN
        RAISE EXCEPTION 'Item name cannot be empty';
    END IF;

    IF p_sku IS NULL OR TRIM(p_sku) = '' THEN
        RAISE EXCEPTION 'SKU cannot be empty';
    END IF;

    IF p_unit_price < 0 THEN
        RAISE EXCEPTION 'Unit price cannot be negative';
    END IF;

    -- Validar categoría
    IF NOT EXISTS (
        SELECT 1 FROM categories
        WHERE id = p_category_id
          AND is_active = TRUE
    ) THEN
        RAISE EXCEPTION 'Category does not exist or is inactive';
    END IF;

    -- Validar duplicado SKU
    IF EXISTS (
        SELECT 1 FROM items
        WHERE LOWER(sku) = LOWER(p_sku)
    ) THEN
        RAISE EXCEPTION 'An item with this SKU already exists';
    END IF;

    INSERT INTO items (
        name,
        sku,
        category_id,
        unit_price
    )
    VALUES (
        TRIM(p_name),
        TRIM(p_sku),
        p_category_id,
        p_unit_price
    );

END;
$$;

CREATE OR REPLACE PROCEDURE sp_update_item(
    p_id UUID,
    p_name VARCHAR,
    p_sku VARCHAR,
    p_category_id UUID,
    p_unit_price NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN

    IF NOT EXISTS (
        SELECT 1 FROM items
        WHERE id = p_id
          AND is_active = TRUE
    ) THEN
        RAISE EXCEPTION 'Item not found';
    END IF;

    IF p_unit_price < 0 THEN
        RAISE EXCEPTION 'Unit price cannot be negative';
    END IF;

    -- Validar categoría
    IF NOT EXISTS (
        SELECT 1 FROM categories
        WHERE id = p_category_id
          AND is_active = TRUE
    ) THEN
        RAISE EXCEPTION 'Category does not exist or is inactive';
    END IF;

    -- Validar SKU duplicado en otro registro
    IF EXISTS (
        SELECT 1 FROM items
        WHERE LOWER(sku) = LOWER(p_sku)
          AND id <> p_id
    ) THEN
        RAISE EXCEPTION 'Another item with this SKU already exists';
    END IF;

    UPDATE items
    SET name = TRIM(p_name),
        sku = TRIM(p_sku),
        category_id = p_category_id,
        unit_price = p_unit_price
    WHERE id = p_id;

END;
$$;

CREATE OR REPLACE PROCEDURE sp_delete_item(
    p_id UUID
)
LANGUAGE plpgsql
AS $$
BEGIN

    IF NOT EXISTS (
        SELECT 1 FROM items
        WHERE id = p_id
          AND is_active = TRUE
    ) THEN
        RAISE EXCEPTION 'Item not found';
    END IF;

    -- Validar stock existente
    IF EXISTS (
        SELECT 1 FROM item_warehouse_stock
        WHERE item_id = p_id
          AND quantity > 0
    ) THEN
        RAISE EXCEPTION 'Cannot delete item with existing stock';
    END IF;

    -- Validar movimientos históricos
    IF EXISTS (
        SELECT 1 FROM inventory_movements
        WHERE item_id = p_id
    ) THEN
        RAISE EXCEPTION 'Cannot delete item with movement history';
    END IF;

    UPDATE items
    SET is_active = FALSE
    WHERE id = p_id;

END;
$$;

CREATE OR REPLACE FUNCTION fn_get_item_by_id(
    p_id UUID
)
RETURNS TABLE (
    id UUID,
    name VARCHAR,
    sku VARCHAR,
    category_id UUID,
    category_name VARCHAR,
    unit_price NUMERIC,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        i.id,
        i.name,
        i.sku,
        c.id,
        c.name,
        i.unit_price,
        i.created_at
    FROM items i
    JOIN categories c ON i.category_id = c.id
    WHERE i.id = p_id
      AND i.is_active = TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION fn_get_items()
RETURNS TABLE (
    id UUID,
    name VARCHAR,
    sku VARCHAR,
    category_name VARCHAR,
    unit_price NUMERIC,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        i.id,
        i.name,
        i.sku,
        c.name,
        i.unit_price,
        i.created_at
    FROM items i
    JOIN categories c ON i.category_id = c.id
    WHERE i.is_active = TRUE
    ORDER BY i.name;
END;
$$;


CREATE OR REPLACE PROCEDURE sp_create_user(
    p_username VARCHAR,
    p_email VARCHAR,
    p_password_hash TEXT,
    p_role_id UUID
)
LANGUAGE plpgsql
AS $$
BEGIN

    IF p_username IS NULL OR TRIM(p_username) = '' THEN
        RAISE EXCEPTION 'Username cannot be empty';
    END IF;

    IF p_email IS NULL OR TRIM(p_email) = '' THEN
        RAISE EXCEPTION 'Email cannot be empty';
    END IF;

    -- Validar rol activo
    IF NOT EXISTS (
        SELECT 1 FROM roles
        WHERE id = p_role_id
          AND is_active = TRUE
    ) THEN
        RAISE EXCEPTION 'Invalid role';
    END IF;

    -- Username único
    IF EXISTS (
        SELECT 1 FROM users
        WHERE LOWER(username) = LOWER(p_username)
          AND is_active = TRUE
    ) THEN
        RAISE EXCEPTION 'Username already exists';
    END IF;

    -- Email único
    IF EXISTS (
        SELECT 1 FROM users
        WHERE LOWER(email) = LOWER(p_email)
          AND is_active = TRUE
    ) THEN
        RAISE EXCEPTION 'Email already exists';
    END IF;

    INSERT INTO users (
        username,
        email,
        password_hash,
        role_id
    )
    VALUES (
        TRIM(p_username),
        LOWER(TRIM(p_email)),
        p_password_hash,
        p_role_id
    );

END;
$$;

CREATE OR REPLACE PROCEDURE sp_update_user(
    p_id UUID,
    p_email VARCHAR,
    p_role_id UUID
)
LANGUAGE plpgsql
AS $$
BEGIN

    IF NOT EXISTS (
        SELECT 1 FROM users
        WHERE id = p_id
          AND is_active = TRUE
    ) THEN
        RAISE EXCEPTION 'User not found';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM roles
        WHERE id = p_role_id
          AND is_active = TRUE
    ) THEN
        RAISE EXCEPTION 'Invalid role';
    END IF;

    -- Validar email duplicado
    IF EXISTS (
        SELECT 1 FROM users
        WHERE LOWER(email) = LOWER(p_email)
          AND id <> p_id
          AND is_active = TRUE
    ) THEN
        RAISE EXCEPTION 'Email already in use';
    END IF;

    UPDATE users
    SET email = LOWER(TRIM(p_email)),
        role_id = p_role_id
    WHERE id = p_id;

END;
$$;

CREATE OR REPLACE PROCEDURE sp_change_user_password(
    p_id UUID,
    p_new_password_hash TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN

    IF NOT EXISTS (
        SELECT 1 FROM users
        WHERE id = p_id
          AND is_active = TRUE
    ) THEN
        RAISE EXCEPTION 'User not found';
    END IF;

    UPDATE users
    SET password_hash = p_new_password_hash
    WHERE id = p_id;

END;
$$;

CREATE OR REPLACE PROCEDURE sp_delete_user(
    p_id UUID
)
LANGUAGE plpgsql
AS $$
BEGIN

    IF NOT EXISTS (
        SELECT 1 FROM users
        WHERE id = p_id
          AND is_active = TRUE
    ) THEN
        RAISE EXCEPTION 'User not found';
    END IF;

    UPDATE users
    SET is_active = FALSE
    WHERE id = p_id;

END;
$$;

CREATE OR REPLACE FUNCTION fn_get_user_by_id(
    p_id UUID
)
RETURNS TABLE (
    id UUID,
    username VARCHAR,
    email VARCHAR,
    role_name VARCHAR,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        u.id,
        u.username,
        u.email,
        r.name,
        u.created_at
    FROM users u
    JOIN roles r ON r.id = u.role_id
    WHERE u.id = p_id
      AND u.is_active = TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION fn_get_users()
RETURNS TABLE (
    id UUID,
    username VARCHAR,
    email VARCHAR,
    role_name VARCHAR,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        u.id,
        u.username,
        u.email,
        r.name,
        u.created_at
    FROM users u
    JOIN roles r ON r.id = u.role_id
    WHERE u.is_active = TRUE
    ORDER BY u.username;
END;
$$;

CREATE OR REPLACE FUNCTION fn_get_user_for_login(
    p_username VARCHAR
)
RETURNS TABLE (
    id UUID,
    username VARCHAR,
    email VARCHAR,
    password_hash TEXT,
    role_name VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        u.id,
        u.username,
        u.email,
        u.password_hash,
        r.name
    FROM users u
    JOIN roles r ON r.id = u.role_id
    WHERE LOWER(u.username) = LOWER(p_username)
      AND u.is_active = TRUE;
END;
$$;