-- ============================================================
-- Transport Cost Analytics – Seed: Carriers & Routes
-- Static reference / dimension data
-- ============================================================

-- ------------------------------------------------------------
-- CARRIERS  (10 fictional European logistics companies)
-- ------------------------------------------------------------
INSERT INTO carriers (carrier_name, country_code, carrier_type, contact_email, is_active) VALUES
    ('EuroFreight GmbH',        'DE', 'road',  'ops@eurofreight.de',      TRUE),
    ('NordTrans AB',            'SE', 'road',  'contact@nordtrans.se',    TRUE),
    ('AlphaLogistics S.A.',     'FR', 'road',  'info@alphalog.fr',        TRUE),
    ('PolaRoad Sp. z o.o.',     'PL', 'road',  'biuro@polaroad.pl',       TRUE),
    ('IberoCargo S.L.',         'ES', 'road',  'ops@iberocargo.es',       TRUE),
    ('AdriaRail d.o.o.',        'HR', 'rail',  'rail@adriarail.hr',       TRUE),
    ('CentralRail A.S.',        'CZ', 'rail',  'info@centralrail.cz',     TRUE),
    ('SkyBridge Air B.V.',      'NL', 'air',   'bookings@skybridge.nl',   TRUE),
    ('MedSea Shipping S.p.A.',  'IT', 'sea',   'cargo@medsea.it',         TRUE),
    ('BalticCargo UAB',         'LT', 'road',  'ops@balticcargo.lt',      FALSE);  -- inactive

-- ------------------------------------------------------------
-- ROUTES  (30 European origin–destination pairs)
-- ------------------------------------------------------------
INSERT INTO routes (origin_city, origin_country, dest_city, dest_country, distance_km, route_type) VALUES
    -- Poland outbound (domestic & international)
    ('Warsaw',      'PL', 'Kraków',      'PL',  291.00, 'domestic'),
    ('Warsaw',      'PL', 'Gdańsk',      'PL',  339.00, 'domestic'),
    ('Warsaw',      'PL', 'Wrocław',     'PL',  351.00, 'domestic'),
    ('Warsaw',      'PL', 'Berlin',      'DE',  574.00, 'international'),
    ('Warsaw',      'PL', 'Vienna',      'AT',  681.00, 'international'),
    ('Warsaw',      'PL', 'Paris',       'FR', 1451.00, 'international'),
    ('Kraków',      'PL', 'Prague',      'CZ',  528.00, 'international'),
    ('Gdańsk',      'PL', 'Stockholm',   'SE', 1100.00, 'international'),

    -- Germany hub
    ('Berlin',      'DE', 'Hamburg',     'DE',  286.00, 'domestic'),
    ('Berlin',      'DE', 'Munich',      'DE',  585.00, 'domestic'),
    ('Berlin',      'DE', 'Amsterdam',   'NL',  649.00, 'international'),
    ('Munich',      'DE', 'Vienna',      'AT',  441.00, 'international'),
    ('Munich',      'DE', 'Milan',       'IT',  818.00, 'international'),
    ('Hamburg',     'DE', 'Copenhagen',  'DK',  308.00, 'international'),
    ('Frankfurt',   'DE', 'Paris',       'FR',  479.00, 'international'),
    ('Frankfurt',   'DE', 'Brussels',    'BE',  359.00, 'international'),

    -- Western Europe
    ('Paris',       'FR', 'Lyon',        'FR',  465.00, 'domestic'),
    ('Paris',       'FR', 'Madrid',      'ES', 1268.00, 'international'),
    ('Amsterdam',   'NL', 'Brussels',    'BE',  210.00, 'international'),
    ('Amsterdam',   'NL', 'London',      'GB',  502.00, 'international'),
    ('Brussels',    'BE', 'Luxembourg',  'LU',  218.00, 'international'),

    -- Southern Europe
    ('Milan',       'IT', 'Rome',        'IT',  531.00, 'domestic'),
    ('Milan',       'IT', 'Barcelona',   'ES',  1000.00,'international'),
    ('Barcelona',   'ES', 'Madrid',      'ES',  621.00, 'domestic'),
    ('Madrid',      'ES', 'Lisbon',      'PT',  625.00, 'international'),

    -- Central & Eastern Europe
    ('Prague',      'CZ', 'Vienna',      'AT',  333.00, 'international'),
    ('Vienna',      'AT', 'Budapest',    'HU',  243.00, 'international'),
    ('Budapest',    'HU', 'Bucharest',   'RO',  843.00, 'international'),
    ('Vilnius',     'LT', 'Riga',        'LV',  301.00, 'international'),
    ('Riga',        'LV', 'Tallinn',     'EE',  311.00, 'international');
