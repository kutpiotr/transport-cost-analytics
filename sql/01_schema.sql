-- ============================================================
-- Transport Cost Analytics – Schema Definition
-- Compatible with: PostgreSQL 15+
-- ============================================================

-- Drop tables in reverse dependency order (safe re-run)
DROP TABLE IF EXISTS delays     CASCADE;
DROP TABLE IF EXISTS costs      CASCADE;
DROP TABLE IF EXISTS shipments  CASCADE;
DROP TABLE IF EXISTS routes     CASCADE;
DROP TABLE IF EXISTS carriers   CASCADE;

-- ------------------------------------------------------------
-- CARRIERS
-- Logistics companies executing the shipments
-- ------------------------------------------------------------
CREATE TABLE carriers (
    carrier_id      SERIAL          PRIMARY KEY,
    carrier_name    VARCHAR(100)    NOT NULL,
    country_code    CHAR(2)         NOT NULL,           -- ISO 3166-1 alpha-2
    carrier_type    VARCHAR(50)     NOT NULL            -- 'road', 'rail', 'air', 'sea'
        CHECK (carrier_type IN ('road', 'rail', 'air', 'sea')),
    contact_email   VARCHAR(150),
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP       NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  carriers              IS 'Logistics carriers executing shipments';
COMMENT ON COLUMN carriers.carrier_type IS 'Transport mode: road, rail, air, sea';

-- ------------------------------------------------------------
-- ROUTES
-- Origin–destination pairs with static distance
-- ------------------------------------------------------------
CREATE TABLE routes (
    route_id        SERIAL          PRIMARY KEY,
    origin_city     VARCHAR(100)    NOT NULL,
    origin_country  CHAR(2)         NOT NULL,
    dest_city       VARCHAR(100)    NOT NULL,
    dest_country    CHAR(2)         NOT NULL,
    distance_km     NUMERIC(8,2)    NOT NULL CHECK (distance_km > 0),
    route_type      VARCHAR(50)     NOT NULL DEFAULT 'international'
        CHECK (route_type IN ('domestic', 'international')),
    created_at      TIMESTAMP       NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  routes              IS 'Pre-defined origin–destination routes with distance';
COMMENT ON COLUMN routes.distance_km IS 'Great-circle or road distance in kilometres';

-- ------------------------------------------------------------
-- SHIPMENTS
-- Individual shipment events
-- ------------------------------------------------------------
CREATE TABLE shipments (
    shipment_id         SERIAL          PRIMARY KEY,
    carrier_id          INT             NOT NULL REFERENCES carriers(carrier_id),
    route_id            INT             NOT NULL REFERENCES routes(route_id),
    shipment_date       DATE            NOT NULL,
    weight_kg           NUMERIC(10,2)   NOT NULL CHECK (weight_kg > 0),
    volume_m3           NUMERIC(10,3),
    cargo_type          VARCHAR(50)     NOT NULL DEFAULT 'general'
        CHECK (cargo_type IN ('general', 'refrigerated', 'hazardous', 'fragile', 'oversized')),
    expected_delivery   DATE            NOT NULL,
    actual_delivery     DATE,                          -- NULL = in transit
    status              VARCHAR(30)     NOT NULL DEFAULT 'in_transit'
        CHECK (status IN ('in_transit', 'delivered', 'cancelled', 'lost')),
    created_at          TIMESTAMP       NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  shipments                   IS 'Individual shipment records';
COMMENT ON COLUMN shipments.weight_kg         IS 'Gross weight of the shipment in kilograms';
COMMENT ON COLUMN shipments.expected_delivery IS 'Promised delivery date at booking';
COMMENT ON COLUMN shipments.actual_delivery   IS 'Actual delivery date; NULL if not yet delivered';

-- ------------------------------------------------------------
-- COSTS
-- Financial breakdown per shipment
-- ------------------------------------------------------------
CREATE TABLE costs (
    cost_id         SERIAL          PRIMARY KEY,
    shipment_id     INT             NOT NULL UNIQUE REFERENCES shipments(shipment_id),
    fuel_cost       NUMERIC(10,2)   NOT NULL CHECK (fuel_cost     >= 0),
    toll_cost       NUMERIC(10,2)   NOT NULL DEFAULT 0 CHECK (toll_cost  >= 0),
    labour_cost     NUMERIC(10,2)   NOT NULL CHECK (labour_cost   >= 0),
    other_cost      NUMERIC(10,2)   NOT NULL DEFAULT 0 CHECK (other_cost >= 0),
    total_cost      NUMERIC(10,2)   GENERATED ALWAYS AS
                        (fuel_cost + toll_cost + labour_cost + other_cost) STORED,
    currency        CHAR(3)         NOT NULL DEFAULT 'EUR',
    recorded_at     TIMESTAMP       NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  costs            IS 'Cost breakdown per shipment (fuel, toll, labour, other)';
COMMENT ON COLUMN costs.total_cost IS 'Computed column: sum of all cost components';

-- ------------------------------------------------------------
-- DELAYS
-- Delay incidents linked to shipments
-- ------------------------------------------------------------
CREATE TABLE delays (
    delay_id        SERIAL          PRIMARY KEY,
    shipment_id     INT             NOT NULL REFERENCES shipments(shipment_id),
    delay_days      INT             NOT NULL CHECK (delay_days > 0),
    delay_reason    VARCHAR(100)    NOT NULL
        CHECK (delay_reason IN (
            'weather', 'customs', 'mechanical', 'traffic',
            'strike', 'recipient_absent', 'address_error', 'other'
        )),
    delay_cost      NUMERIC(10,2)   DEFAULT 0 CHECK (delay_cost >= 0),
    reported_at     TIMESTAMP       NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  delays             IS 'Delay incidents; one shipment may have multiple delay records';
COMMENT ON COLUMN delays.delay_days  IS 'Number of calendar days the shipment was delayed';
COMMENT ON COLUMN delays.delay_cost  IS 'Additional cost incurred due to this delay';

-- ------------------------------------------------------------
-- INDEXES for query performance
-- ------------------------------------------------------------
CREATE INDEX idx_shipments_carrier   ON shipments(carrier_id);
CREATE INDEX idx_shipments_route     ON shipments(route_id);
CREATE INDEX idx_shipments_date      ON shipments(shipment_date);
CREATE INDEX idx_shipments_status    ON shipments(status);
CREATE INDEX idx_delays_shipment     ON delays(shipment_id);
CREATE INDEX idx_costs_shipment      ON costs(shipment_id);
