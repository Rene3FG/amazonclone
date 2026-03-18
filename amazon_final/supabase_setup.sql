-- ============================================================
-- AMAZON 2026 — Supabase SQL Setup
-- Ejecuta este script completo en el SQL Editor de Supabase
-- ============================================================

-- ── 1. Tabla: cart ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cart (
  id         uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id    uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id int         NOT NULL,
  quantity   int         NOT NULL DEFAULT 1 CHECK (quantity > 0),
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, product_id)
);

-- ── 2. Tabla: orders ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS orders (
  id               uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id          uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  total_amount     numeric     NOT NULL,
  status           int         NOT NULL DEFAULT 0,  -- 0=processing 1=shipped 2=delivered 3=cancelled
  shipping_address text,
  card_last4       varchar(4),
  created_at       timestamptz DEFAULT now(),
  updated_at       timestamptz DEFAULT now()
);

-- ── 3. Tabla: order_items ────────────────────────────────────
CREATE TABLE IF NOT EXISTS order_items (
  id         uuid    DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id   uuid    NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id int     NOT NULL,
  quantity   int     NOT NULL DEFAULT 1,
  price      numeric NOT NULL
);

-- ── 4. Tabla: reviews ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS reviews (
  id         uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id    uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  user_email text        NOT NULL,
  product_id int         NOT NULL,
  rating     numeric     NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment    text        NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, product_id)
);

-- ── 5. Tabla: wishlist (nueva) ───────────────────────────────
CREATE TABLE IF NOT EXISTS wishlist (
  id         uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id    uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id int         NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, product_id)
);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- CRÍTICO: sin esto cualquier usuario ve datos de todos
-- ============================================================

ALTER TABLE cart        ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders      ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews     ENABLE ROW LEVEL SECURITY;
ALTER TABLE wishlist    ENABLE ROW LEVEL SECURITY;

-- Cart: solo el dueño
DROP POLICY IF EXISTS "cart_owner" ON cart;
CREATE POLICY "cart_owner" ON cart
  USING     (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Orders: solo el dueño
DROP POLICY IF EXISTS "orders_owner" ON orders;
CREATE POLICY "orders_owner" ON orders
  USING     (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Order items: acceso a través del pedido del dueño
DROP POLICY IF EXISTS "order_items_via_order" ON order_items;
CREATE POLICY "order_items_via_order" ON order_items
  USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id      = order_items.order_id
        AND orders.user_id = auth.uid()
    )
  );

-- Reviews: lectura pública, escritura solo propia
DROP POLICY IF EXISTS "reviews_read_public" ON reviews;
CREATE POLICY "reviews_read_public" ON reviews
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "reviews_own_write" ON reviews;
CREATE POLICY "reviews_own_write" ON reviews
  FOR ALL
  USING     (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Wishlist: solo el dueño
DROP POLICY IF EXISTS "wishlist_owner" ON wishlist;
CREATE POLICY "wishlist_owner" ON wishlist
  USING     (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- ÍNDICES DE RENDIMIENTO
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_orders_user_created
  ON orders(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id
  ON order_items(order_id);

CREATE INDEX IF NOT EXISTS idx_reviews_product_id
  ON reviews(product_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_cart_user_id
  ON cart(user_id);

CREATE INDEX IF NOT EXISTS idx_wishlist_user_id
  ON wishlist(user_id);

-- ============================================================
-- FUNCIÓN: auto-actualizar updated_at en orders
-- ============================================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS orders_updated_at ON orders;
CREATE TRIGGER orders_updated_at
  BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- FUNCIÓN: cambiar status de orden (segura)
-- ============================================================

CREATE OR REPLACE FUNCTION update_order_status(
  p_order_id uuid,
  p_status   int
) RETURNS void AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM orders
    WHERE id = p_order_id AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'No autorizado o pedido no encontrado';
  END IF;

  UPDATE orders
  SET    status     = p_status,
         updated_at = now()
  WHERE  id = p_order_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- VISTA: order_summary (elimina el N+1 del OrderRepo)
-- ============================================================

CREATE OR REPLACE VIEW order_summary AS
SELECT
  o.id,
  o.user_id,
  o.total_amount,
  o.status,
  o.created_at,
  o.updated_at,
  o.shipping_address,
  o.card_last4,
  json_agg(
    json_build_object(
      'product_id', oi.product_id,
      'quantity',   oi.quantity,
      'price',      oi.price
    )
  ) AS items
FROM orders o
JOIN order_items oi ON oi.order_id = o.id
GROUP BY o.id;
