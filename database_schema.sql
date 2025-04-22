// Database Schema Design for RC Hub Application

// 1. Users Table (handled by Supabase Auth)
// This table is automatically created and managed by Supabase Auth
// Fields:
// - id (UUID, primary key)
// - email (string)
// - created_at (timestamp)
// - updated_at (timestamp)

// 2. Vehicles Table
CREATE TABLE vehicles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  brand VARCHAR(255),
  model VARCHAR(255),
  category VARCHAR(50) NOT NULL, -- car, plane, boat, etc.
  scale VARCHAR(50), -- 1:10, 1:8, etc.
  year INTEGER,
  description TEXT,
  purchase_date DATE,
  purchase_price DECIMAL(10, 2),
  status VARCHAR(50) NOT NULL DEFAULT 'active', -- active, in_repair, retired, etc.
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

// 3. Vehicle Media Table
CREATE TABLE vehicle_media (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
  media_type VARCHAR(50) NOT NULL, -- image, video
  url TEXT NOT NULL,
  thumbnail_url TEXT,
  title VARCHAR(255),
  description TEXT,
  is_primary BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

// 4. Parts Table
CREATE TABLE parts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  part_number VARCHAR(100),
  brand VARCHAR(255),
  category VARCHAR(50) NOT NULL, -- engine, suspension, electronics, etc.
  description TEXT,
  purchase_date DATE,
  purchase_price DECIMAL(10, 2),
  quantity INTEGER NOT NULL DEFAULT 1,
  min_quantity INTEGER DEFAULT 0, -- for inventory alerts
  compatible_models TEXT[], -- array of compatible vehicle models
  status VARCHAR(50) NOT NULL DEFAULT 'in_stock', -- in_stock, low_stock, out_of_stock, etc.
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

// 5. Part Media Table
CREATE TABLE part_media (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  part_id UUID NOT NULL REFERENCES parts(id) ON DELETE CASCADE,
  media_type VARCHAR(50) NOT NULL, -- image, diagram, manual
  url TEXT NOT NULL,
  thumbnail_url TEXT,
  title VARCHAR(255),
  description TEXT,
  is_primary BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

// 6. Vehicle Parts Junction Table (for parts installed on vehicles)
CREATE TABLE vehicle_parts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
  part_id UUID NOT NULL REFERENCES parts(id) ON DELETE CASCADE,
  installation_date DATE,
  notes TEXT,
  status VARCHAR(50) NOT NULL DEFAULT 'installed', -- installed, pending_replacement, removed
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(vehicle_id, part_id)
);

// 7. Maintenance Records Table
CREATE TABLE maintenance_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  maintenance_date DATE NOT NULL,
  maintenance_type VARCHAR(50) NOT NULL, -- repair, upgrade, routine
  cost DECIMAL(10, 2),
  performed_by VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

// 8. Diagnostics Table (for AI-assisted diagnostics)
CREATE TABLE diagnostics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  vehicle_id UUID REFERENCES vehicles(id) ON DELETE SET NULL,
  issue_description TEXT NOT NULL,
  diagnosis_result TEXT,
  suggested_parts TEXT[],
  status VARCHAR(50) NOT NULL DEFAULT 'pending', -- pending, diagnosed, resolved
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

// 9. Diagnostic Media Table
CREATE TABLE diagnostic_media (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  diagnostic_id UUID NOT NULL REFERENCES diagnostics(id) ON DELETE CASCADE,
  media_type VARCHAR(50) NOT NULL, -- image, video
  url TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

// 10. Part Diagrams Table (for interactive parts viewer)
CREATE TABLE part_diagrams (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  part_id UUID NOT NULL REFERENCES parts(id) ON DELETE CASCADE,
  diagram_type VARCHAR(50) NOT NULL, -- exploded_view, schematic, 3d_model
  url TEXT NOT NULL,
  hotspots JSONB, -- JSON array of clickable areas with coordinates and linked part info
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

// Indexes for performance
CREATE INDEX idx_vehicles_user_id ON vehicles(user_id);
CREATE INDEX idx_parts_user_id ON parts(user_id);
CREATE INDEX idx_vehicle_parts_vehicle_id ON vehicle_parts(vehicle_id);
CREATE INDEX idx_vehicle_parts_part_id ON vehicle_parts(part_id);
CREATE INDEX idx_diagnostics_user_id ON diagnostics(user_id);
CREATE INDEX idx_diagnostics_vehicle_id ON diagnostics(vehicle_id);

// Row Level Security Policies (RLS)
-- Vehicles: Users can only access their own vehicles
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
CREATE POLICY vehicles_policy ON vehicles 
  USING (user_id = auth.uid());

-- Parts: Users can only access their own parts
ALTER TABLE parts ENABLE ROW LEVEL SECURITY;
CREATE POLICY parts_policy ON parts 
  USING (user_id = auth.uid());

-- Vehicle Media: Users can only access media for their own vehicles
ALTER TABLE vehicle_media ENABLE ROW LEVEL SECURITY;
CREATE POLICY vehicle_media_policy ON vehicle_media 
  USING (vehicle_id IN (SELECT id FROM vehicles WHERE user_id = auth.uid()));

-- Part Media: Users can only access media for their own parts
ALTER TABLE part_media ENABLE ROW LEVEL SECURITY;
CREATE POLICY part_media_policy ON part_media 
  USING (part_id IN (SELECT id FROM parts WHERE user_id = auth.uid()));

-- Vehicle Parts: Users can only access parts installed on their own vehicles
ALTER TABLE vehicle_parts ENABLE ROW LEVEL SECURITY;
CREATE POLICY vehicle_parts_policy ON vehicle_parts 
  USING (vehicle_id IN (SELECT id FROM vehicles WHERE user_id = auth.uid()));

-- Maintenance Records: Users can only access records for their own vehicles
ALTER TABLE maintenance_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY maintenance_records_policy ON maintenance_records 
  USING (vehicle_id IN (SELECT id FROM vehicles WHERE user_id = auth.uid()));

-- Diagnostics: Users can only access their own diagnostics
ALTER TABLE diagnostics ENABLE ROW LEVEL SECURITY;
CREATE POLICY diagnostics_policy ON diagnostics 
  USING (user_id = auth.uid());

-- Diagnostic Media: Users can only access media for their own diagnostics
ALTER TABLE diagnostic_media ENABLE ROW LEVEL SECURITY;
CREATE POLICY diagnostic_media_policy ON diagnostic_media 
  USING (diagnostic_id IN (SELECT id FROM diagnostics WHERE user_id = auth.uid()));

-- Part Diagrams: Users can only access diagrams for their own parts
ALTER TABLE part_diagrams ENABLE ROW LEVEL SECURITY;
CREATE POLICY part_diagrams_policy ON part_diagrams 
  USING (part_id IN (SELECT id FROM parts WHERE user_id = auth.uid()));
