#!/bin/bash

# PostgreSQL Multi-Database Setup Script
# Creates Docker container with food delivery and school management databases
# Author: Claude AI
# Date: $(date)

set -e  # Exit on any error

# Configuration
CONTAINER_NAME="postgres_multidb"
POSTGRES_PASSWORD="admin123"
POSTGRES_USER="postgres"
DB_PORT="5432"
FOOD_DB_NAME="food_delivery_db"
SCHOOL_DB_NAME="school_management_db"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        error "Docker is not running. Please start Docker and try again."
    fi
    log "Docker is running"
}

# Remove existing container if it exists
cleanup_existing() {
    if docker ps -a | grep -q "$CONTAINER_NAME"; then
        warn "Removing existing container: $CONTAINER_NAME"
        docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
        docker rm "$CONTAINER_NAME" >/dev/null 2>&1 || true
    fi
}

# Start PostgreSQL container
start_postgres() {
    log "Starting PostgreSQL container..."
    docker run -d \
        --name "$CONTAINER_NAME" \
        -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
        -e POSTGRES_USER="$POSTGRES_USER" \
        -p "$DB_PORT:5432" \
        postgres:15-alpine

    # Wait for PostgreSQL to be ready
    log "Waiting for PostgreSQL to be ready..."
    sleep 10
    
    # Check if container is running
    if ! docker ps | grep -q "$CONTAINER_NAME"; then
        error "Failed to start PostgreSQL container"
    fi
    
    log "PostgreSQL container started successfully"
}

# Create databases
create_databases() {
    log "Creating databases..."
    
    docker exec -it "$CONTAINER_NAME" psql -U "$POSTGRES_USER" -c "CREATE DATABASE $FOOD_DB_NAME;"
    docker exec -it "$CONTAINER_NAME" psql -U "$POSTGRES_USER" -c "CREATE DATABASE $SCHOOL_DB_NAME;"
    
    log "Databases created successfully"
}

# Generate fake data using online APIs and create SQL files
generate_fake_data() {
    log "Generating fake data..."
    
    # Create temporary directory for SQL files
    mkdir -p /tmp/postgres_seed
    
    # Generate Food Delivery Database Schema and Data
    cat > /tmp/postgres_seed/food_delivery_schema.sql << 'EOF'
-- Food Delivery Database Schema

-- Users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Addresses table
CREATE TABLE addresses (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    street_address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(50) NOT NULL,
    zip_code VARCHAR(10) NOT NULL,
    country VARCHAR(50) DEFAULT 'USA',
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Restaurants table
CREATE TABLE restaurants (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    cuisine_type VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(255),
    street_address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(50) NOT NULL,
    zip_code VARCHAR(10) NOT NULL,
    rating DECIMAL(3,2) DEFAULT 0.00,
    delivery_fee DECIMAL(8,2) DEFAULT 0.00,
    minimum_order DECIMAL(8,2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Menu categories table
CREATE TABLE menu_categories (
    id SERIAL PRIMARY KEY,
    restaurant_id INTEGER REFERENCES restaurants(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    sort_order INTEGER DEFAULT 0
);

-- Menu items table
CREATE TABLE menu_items (
    id SERIAL PRIMARY KEY,
    restaurant_id INTEGER REFERENCES restaurants(id) ON DELETE CASCADE,
    category_id INTEGER REFERENCES menu_categories(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(8,2) NOT NULL,
    image_url VARCHAR(500),
    is_available BOOLEAN DEFAULT TRUE,
    preparation_time INTEGER DEFAULT 15, -- in minutes
    calories INTEGER,
    is_vegetarian BOOLEAN DEFAULT FALSE,
    is_vegan BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Orders table
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    restaurant_id INTEGER REFERENCES restaurants(id) ON DELETE CASCADE,
    delivery_address_id INTEGER REFERENCES addresses(id),
    order_number VARCHAR(50) UNIQUE NOT NULL,
    status VARCHAR(50) DEFAULT 'pending', -- pending, confirmed, preparing, out_for_delivery, delivered, cancelled
    subtotal DECIMAL(10,2) NOT NULL,
    delivery_fee DECIMAL(8,2) DEFAULT 0.00,
    tax_amount DECIMAL(8,2) DEFAULT 0.00,
    tip_amount DECIMAL(8,2) DEFAULT 0.00,
    total_amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(50),
    special_instructions TEXT,
    estimated_delivery_time TIMESTAMP,
    actual_delivery_time TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Order items table
CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    menu_item_id INTEGER REFERENCES menu_items(id),
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price DECIMAL(8,2) NOT NULL,
    total_price DECIMAL(8,2) NOT NULL,
    special_instructions TEXT
);

-- Reviews table
CREATE TABLE reviews (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    restaurant_id INTEGER REFERENCES restaurants(id) ON DELETE CASCADE,
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_addresses_user_id ON addresses(user_id);
CREATE INDEX idx_restaurants_cuisine ON restaurants(cuisine_type);
CREATE INDEX idx_restaurants_rating ON restaurants(rating);
CREATE INDEX idx_menu_items_restaurant ON menu_items(restaurant_id);
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_restaurant_id ON orders(restaurant_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_reviews_restaurant_id ON reviews(restaurant_id);
EOF

    # Generate School Management Database Schema
    cat > /tmp/postgres_seed/school_management_schema.sql << 'EOF'
-- School Management Database Schema

-- Schools table
CREATE TABLE schools (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(50) NOT NULL,
    zip_code VARCHAR(10) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    website VARCHAR(255),
    principal_name VARCHAR(255),
    established_year INTEGER,
    total_capacity INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Departments table
CREATE TABLE departments (
    id SERIAL PRIMARY KEY,
    school_id INTEGER REFERENCES schools(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    head_teacher_id INTEGER,
    budget DECIMAL(12,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Teachers table
CREATE TABLE teachers (
    id SERIAL PRIMARY KEY,
    school_id INTEGER REFERENCES schools(id) ON DELETE CASCADE,
    department_id INTEGER REFERENCES departments(id) ON DELETE SET NULL,
    employee_id VARCHAR(50) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    date_of_birth DATE,
    hire_date DATE NOT NULL,
    salary DECIMAL(10,2),
    qualification VARCHAR(255),
    specialization VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Students table
CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    school_id INTEGER REFERENCES schools(id) ON DELETE CASCADE,
    student_id VARCHAR(50) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20),
    date_of_birth DATE NOT NULL,
    gender VARCHAR(10),
    address VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code VARCHAR(10),
    parent_name VARCHAR(255),
    parent_phone VARCHAR(20),
    parent_email VARCHAR(255),
    enrollment_date DATE NOT NULL,
    graduation_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Classes table
CREATE TABLE classes (
    id SERIAL PRIMARY KEY,
    school_id INTEGER REFERENCES schools(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    grade_level INTEGER NOT NULL,
    section VARCHAR(10),
    academic_year VARCHAR(10) NOT NULL,
    max_students INTEGER DEFAULT 30,
    room_number VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Subjects table
CREATE TABLE subjects (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) UNIQUE NOT NULL,
    description TEXT,
    credits INTEGER DEFAULT 1,
    is_mandatory BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Class subjects table (many-to-many relationship)
CREATE TABLE class_subjects (
    id SERIAL PRIMARY KEY,
    class_id INTEGER REFERENCES classes(id) ON DELETE CASCADE,
    subject_id INTEGER REFERENCES subjects(id) ON DELETE CASCADE,
    teacher_id INTEGER REFERENCES teachers(id) ON DELETE SET NULL,
    schedule_day VARCHAR(20), -- Monday, Tuesday, etc.
    start_time TIME,
    end_time TIME,
    UNIQUE(class_id, subject_id)
);

-- Student enrollments table
CREATE TABLE student_enrollments (
    id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES students(id) ON DELETE CASCADE,
    class_id INTEGER REFERENCES classes(id) ON DELETE CASCADE,
    enrollment_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'active', -- active, transferred, graduated, dropped
    UNIQUE(student_id, class_id)
);

-- Exams table
CREATE TABLE exams (
    id SERIAL PRIMARY KEY,
    subject_id INTEGER REFERENCES subjects(id) ON DELETE CASCADE,
    class_id INTEGER REFERENCES classes(id) ON DELETE CASCADE,
    teacher_id INTEGER REFERENCES teachers(id) ON DELETE SET NULL,
    exam_name VARCHAR(255) NOT NULL,
    exam_type VARCHAR(50), -- midterm, final, quiz, assignment
    exam_date DATE NOT NULL,
    max_marks INTEGER NOT NULL,
    duration_minutes INTEGER,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Student grades table
CREATE TABLE student_grades (
    id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES students(id) ON DELETE CASCADE,
    exam_id INTEGER REFERENCES exams(id) ON DELETE CASCADE,
    marks_obtained DECIMAL(5,2) NOT NULL,
    grade VARCHAR(5),
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(student_id, exam_id)
);

-- Attendance table
CREATE TABLE attendance (
    id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES students(id) ON DELETE CASCADE,
    class_id INTEGER REFERENCES classes(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'present', -- present, absent, late, excused
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(student_id, class_id, date)
);

-- Add foreign key constraint for department head
ALTER TABLE departments ADD CONSTRAINT fk_departments_head_teacher 
    FOREIGN KEY (head_teacher_id) REFERENCES teachers(id);

-- Create indexes for better performance
CREATE INDEX idx_teachers_school_id ON teachers(school_id);
CREATE INDEX idx_teachers_department_id ON teachers(department_id);
CREATE INDEX idx_students_school_id ON students(school_id);
CREATE INDEX idx_students_student_id ON students(student_id);
CREATE INDEX idx_classes_school_id ON classes(school_id);
CREATE INDEX idx_class_subjects_class_id ON class_subjects(class_id);
CREATE INDEX idx_class_subjects_teacher_id ON class_subjects(teacher_id);
CREATE INDEX idx_student_enrollments_student_id ON student_enrollments(student_id);
CREATE INDEX idx_student_enrollments_class_id ON student_enrollments(class_id);
CREATE INDEX idx_exams_class_id ON exams(class_id);
CREATE INDEX idx_student_grades_student_id ON student_grades(student_id);
CREATE INDEX idx_attendance_student_id ON attendance(student_id);
CREATE INDEX idx_attendance_date ON attendance(date);
EOF

    log "Database schemas created"
}

# Generate realistic sample data
generate_sample_data() {
    log "Generating sample data files..."
    
    # Food Delivery Sample Data
    cat > /tmp/postgres_seed/food_delivery_data.sql << 'EOF'
-- Food Delivery Sample Data

-- Insert sample users
INSERT INTO users (email, password_hash, first_name, last_name, phone) VALUES
('john.doe@email.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewrUOp7CL4RLR.NC', 'John', 'Doe', '555-0101'),
('jane.smith@email.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewrUOp7CL4RLR.NC', 'Jane', 'Smith', '555-0102'),
('mike.johnson@email.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewrUOp7CL4RLR.NC', 'Mike', 'Johnson', '555-0103'),
('sarah.wilson@email.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewrUOp7CL4RLR.NC', 'Sarah', 'Wilson', '555-0104'),
('david.brown@email.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewrUOp7CL4RLR.NC', 'David', 'Brown', '555-0105'),
('lisa.garcia@email.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewrUOp7CL4RLR.NC', 'Lisa', 'Garcia', '555-0106'),
('robert.davis@email.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewrUOp7CL4RLR.NC', 'Robert', 'Davis', '555-0107'),
('emily.miller@email.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewrUOp7CL4RLR.NC', 'Emily', 'Miller', '555-0108'),
('chris.anderson@email.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewrUOp7CL4RLR.NC', 'Chris', 'Anderson', '555-0109'),
('amanda.taylor@email.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewrUOp7CL4RLR.NC', 'Amanda', 'Taylor', '555-0110');

-- Insert sample addresses
INSERT INTO addresses (user_id, street_address, city, state, zip_code, is_default) VALUES
(1, '123 Main St', 'New York', 'NY', '10001', true),
(2, '456 Oak Ave', 'Los Angeles', 'CA', '90210', true),
(3, '789 Pine Rd', 'Chicago', 'IL', '60601', true),
(4, '321 Elm St', 'Houston', 'TX', '77001', true),
(5, '654 Maple Dr', 'Phoenix', 'AZ', '85001', true),
(6, '987 Cedar Ln', 'Philadelphia', 'PA', '19101', true),
(7, '147 Birch St', 'San Antonio', 'TX', '78201', true),
(8, '258 Walnut Ave', 'San Diego', 'CA', '92101', true),
(9, '369 Spruce Rd', 'Dallas', 'TX', '75201', true),
(10, '741 Ash Dr', 'San Jose', 'CA', '95101', true);

-- Insert sample restaurants
INSERT INTO restaurants (name, description, cuisine_type, phone, email, street_address, city, state, zip_code, rating, delivery_fee, minimum_order) VALUES
('Mama Mia Pizzeria', 'Authentic Italian pizza and pasta', 'Italian', '555-1001', 'orders@mamamia.com', '100 Restaurant Row', 'New York', 'NY', '10001', 4.5, 2.99, 15.00),
('Dragon Palace', 'Traditional Chinese cuisine', 'Chinese', '555-1002', 'info@dragonpalace.com', '200 Food Street', 'Los Angeles', 'CA', '90210', 4.2, 3.50, 20.00),
('Burger Central', 'Gourmet burgers and fries', 'American', '555-1003', 'hello@burgercentral.com', '300 Dining Ave', 'Chicago', 'IL', '60601', 4.0, 2.50, 12.00),
('Spice Route', 'Authentic Indian flavors', 'Indian', '555-1004', 'contact@spiceroute.com', '400 Curry Lane', 'Houston', 'TX', '77001', 4.7, 4.00, 18.00),
('Taco Libre', 'Fresh Mexican street food', 'Mexican', '555-1005', 'orders@tacolibre.com', '500 Fiesta Blvd', 'Phoenix', 'AZ', '85001', 4.3, 2.25, 10.00),
('Sakura Sushi', 'Fresh sushi and Japanese cuisine', 'Japanese', '555-1006', 'info@sakurasushi.com', '600 Zen Street', 'Philadelphia', 'PA', '19101', 4.6, 3.75, 25.00),
('The Green Bowl', 'Healthy salads and bowls', 'Healthy', '555-1007', 'hello@greenbowl.com', '700 Health Ave', 'San Antonio', 'TX', '78201', 4.4, 1.99, 8.00),
('BBQ Masters', 'Slow-cooked barbecue specialties', 'BBQ', '555-1008', 'orders@bbqmasters.com', '800 Smoke Trail', 'San Diego', 'CA', '92101', 4.1, 3.25, 16.00),
('Noodle Express', 'Quick Asian noodle dishes', 'Asian', '555-1009', 'info@noodleexpress.com', '900 Quick Bite St', 'Dallas', 'TX', '75201', 3.9, 2.75, 14.00),
('Mediterranean Delight', 'Fresh Mediterranean cuisine', 'Mediterranean', '555-1010', 'contact@meddelight.com', '1000 Olive Grove', 'San Jose', 'CA', '95101', 4.8, 4.50, 22.00);

-- Insert menu categories
INSERT INTO menu_categories (restaurant_id, name, description) VALUES
(1, 'Pizzas', 'Hand-tossed pizzas with fresh ingredients'),
(1, 'Pasta', 'Traditional Italian pasta dishes'),
(1, 'Appetizers', 'Starters and small plates'),
(2, 'Appetizers', 'Traditional Chinese starters'),
(2, 'Main Dishes', 'Signature Chinese entrees'),
(2, 'Noodles & Rice', 'Noodle and rice specialties'),
(3, 'Burgers', 'Gourmet burger selection'),
(3, 'Sides', 'Fries, onion rings, and more'),
(3, 'Drinks', 'Beverages and shakes'),
(4, 'Curry Dishes', 'Traditional Indian curries'),
(4, 'Tandoor Items', 'Clay oven specialties'),
(4, 'Breads', 'Fresh Indian breads'),
(5, 'Tacos', 'Authentic Mexican tacos'),
(5, 'Burritos', 'Large flour tortilla wraps'),
(5, 'Appetizers', 'Mexican starters');

-- Insert menu items
INSERT INTO menu_items (restaurant_id, category_id, name, description, price, is_available, preparation_time, calories, is_vegetarian) VALUES
-- Mama Mia Pizzeria
(1, 1, 'Margherita Pizza', 'Fresh mozzarella, tomato sauce, basil', 16.99, true, 20, 850, true),
(1, 1, 'Pepperoni Pizza', 'Classic pepperoni with mozzarella', 18.99, true, 20, 950, false),
(1, 1, 'Supreme Pizza', 'Pepperoni, sausage, peppers, onions, mushrooms', 22.99, true, 25, 1100, false),
(1, 2, 'Spaghetti Carbonara', 'Creamy pasta with bacon and parmesan', 15.99, true, 15, 750, false),
(1, 2, 'Penne Arrabbiata', 'Spicy tomato sauce with penne pasta', 14.99, true, 12, 680, true),
(1, 3, 'Garlic Bread', 'Fresh bread with garlic butter', 6.99, true, 8, 320, true),
-- Dragon Palace
(2, 4, 'Spring Rolls', 'Crispy vegetable spring rolls (2 pieces)', 7.99, true, 10, 280, true),
(2, 4, 'Pot Stickers', 'Pan-fried pork dumplings (6 pieces)', 9.99, true, 12, 420, false),
(2, 5, 'General Tso Chicken', 'Sweet and spicy battered chicken', 16.99, true, 18, 850, false),
(2, 5, 'Beef and Broccoli', 'Tender beef with fresh broccoli', 17.99, true, 15, 650, false),
(2, 6, 'Lo Mein Noodles', 'Soft noodles with vegetables', 13.99, true, 12, 580, true),
(2, 6, 'Fried Rice', 'Wok-fried rice with egg and vegetables', 12.99, true, 10, 520, true),
-- Burger Central
(3, 7, 'Classic Cheeseburger', '1/4 lb beef patty with cheese', 12.99, true, 15, 650, false),
(3, 7, 'BBQ Bacon Burger', 'Beef patty with BBQ sauce and bacon', 15.99, true, 18, 780, false),
(3, 7, 'Veggie Burger', 'Plant-based patty with fresh toppings', 13.99, true, 12, 480, true),
(3, 8, 'French Fries', 'Crispy golden fries', 4.99, true, 8, 350, true),
(3, 8, 'Onion Rings', 'Beer-battered onion rings', 6.99, true, 10, 420, true),
-- Spice Route
(4, 10, 'Chicken Tikka Masala', 'Creamy tomato curry with chicken', 18.99, true, 20, 720, false),
(4, 10, 'Lamb Curry', 'Traditional lamb curry with spices', 21.99, true, 25, 680, false),
(4, 10, 'Palak Paneer', 'Spinach curry with cottage cheese', 16.99, true, 18, 520, true),
(4, 11, 'Chicken Tandoori', 'Clay oven roasted chicken', 19.99, true, 30, 580, false),
(4, 12, 'Naan Bread', 'Fresh baked Indian bread', 3.99, true, 8, 180, true),
-- Taco Libre
(5, 13, 'Beef Tacos', 'Seasoned ground beef tacos (3 pieces)', 8.99, true, 10, 450, false),
(5, 13, 'Chicken Tacos', 'Grilled chicken tacos (3 pieces)', 9.99, true, 12, 420, false),
(5, 13, 'Fish Tacos', 'Grilled fish with cabbage slaw (3 pieces)', 11.99, true, 15, 380, false),
(5, 14, 'Chicken Burrito', 'Large burrito with chicken and beans', 12.99, true, 12, 650, false),
(5, 14, 'Veggie Burrito', 'Bean and vegetable burrito', 10.99, true, 10, 520, true),
(5, 15, 'Guacamole and Chips', 'Fresh guacamole with tortilla chips', 7.99, true, 5, 280, true);

-- Generate sample orders (last 30 days)
INSERT INTO orders (user_id, restaurant_id, delivery_address_id, order_number, status, subtotal, delivery_fee, tax_amount, tip_amount, total_amount, payment_method, estimated_delivery_time, actual_delivery_time) VALUES
(1, 1, 1, 'ORD-001', 'delivered', 35.98, 2.99, 3.24, 5.00, 47.21, 'credit_card', '2024-01-15 19:30:00', '2024-01-15 19:25:00'),
(2, 2, 2, 'ORD-002', 'delivered', 42.97, 3.50, 3.87, 6.00, 56.34, 'debit_card', '2024-01-16 20:15:00', '2024-01-16 20:10:00'),
(3, 3, 3, 'ORD-003', 'delivered', 28.97, 2.50, 2.61, 4.00, 38.08, 'cash', '2024-01-17 18:45:00', '2024-01-17 18:50:00'),
(4, 4, 4, 'ORD-004', 'delivered', 38.98, 4.00, 3.51, 5.50, 51.99, 'credit_card', '2024-01-18 19:00:00', '2024-01-18 19:05:00'),
(5, 5, 5, 'ORD-005', 'delivered', 21.98, 2.25, 1.98, 3.00, 29.21, 'paypal', '2024-01-19 20:30:00', '2024-01-19 20:25:00'),
(6, 6, 6, 'ORD-006', 'delivered', 45.99, 3.75, 4.14, 7.00, 60.88, 'credit_card', '2024-01-20 19:45:00', '2024-01-20 19:40:00'),
(7, 7, 7, 'ORD-007', 'delivered', 25.98, 1.99, 2.34, 3.50, 33.81, 'debit_card', '2024-01-21 18:15:00', '2024-01-21 18:20:00'),
(8, 8, 8, 'ORD-008', 'delivered', 32.99, 3.25, 2.97, 4.50, 43.71, 'cash', '2024-01-22 20:00:00', '2024-01-22 19:55:00'),
(9, 9, 9, 'ORD-009', 'preparing', 27.98, 2.75, 2.52, 4.00, 37.25, 'credit_card', '2024-01-23 19:30:00', NULL),
(10, 10, 10, 'ORD-010', 'confirmed', 55.99, 4.50, 5.04, 8.00, 73.53, 'paypal', '2024-01-24 20:45:00', NULL);

-- Insert order items
INSERT INTO order_items (order_id, menu_item_id, quantity, unit_price, total_price) VALUES
-- Order 1 (Mama Mia)
(1, 1, 1, 16.99, 16.99),
(1, 2, 1, 18.99, 18.99),
-- Order 2 (Dragon Palace)
(2, 7, 2, 7.99, 15.98),
(2, 9, 1, 16.99, 16.99),
(2, 11, 1, 13.99, 13.99),
-- Order 3 (Burger Central)
(3, 13, 2, 12.99, 25.98),
(3, 16, 1, 4.99, 4.99),
-- Order 4 (Spice Route)
(4, 18, 1, 18.99, 18.99),
(4, 20, 1, 19.99, 19.99),
-- Order 5 (Taco Libre)
(5, 22, 1, 8.99, 8.99),
(5, 24, 1, 12.99, 12.99),
-- Order 6 (Sakura Sushi - not in menu items, using existing)
(6, 1, 2, 22.99, 45.98),
-- Order 7 (Green Bowl - using existing)
(7, 13, 2, 12.99, 25.98),
-- Order 8 (BBQ Masters - using existing)
(8, 15, 1, 15.99, 15.99),
(8, 16, 2, 8.50, 17.00),
-- Order 9 (Noodle Express - using existing)
(9, 11, 2, 13.99, 27.98),
-- Order 10 (Mediterranean Delight - using existing)
(10, 1, 1, 22.99, 22.99),
(10, 2, 1, 18.99, 18.99),
(10, 3, 1, 14.99, 14.99);

-- Insert reviews
INSERT INTO reviews (user_id, restaurant_id, order_id, rating, comment) VALUES
(1, 1, 1, 5, 'Amazing pizza! Delivered hot and fresh. Will definitely order again.'),
(2, 2, 2, 4, 'Good Chinese food, but delivery was a bit slow.'),
(3, 3, 3, 4, 'Great burgers, fries were crispy. Good value for money.'),
(4, 4, 4, 5, 'Excellent Indian food! The curry was perfectly spiced.'),
(5, 5, 5, 4, 'Fresh tacos, good portion sizes. Quick delivery.'),
(6, 6, 6, 5, 'Best sushi in town! Fresh ingredients and great presentation.'),
(7, 7, 7, 4, 'Healthy options, good for diet. Could use more flavor.'),
(8, 8, 8, 3, 'BBQ was okay, but a bit dry. Service was good though.');
EOF

    # School Management Sample Data
    cat > /tmp/postgres_seed/school_management_data.sql << 'EOF'
-- School Management Sample Data

-- Insert sample schools
INSERT INTO schools (name, address, city, state, zip_code, phone, email, website, principal_name, established_year, total_capacity) VALUES
('Lincoln Elementary School', '123 Education St', 'Springfield', 'IL', '62701', '217-555-0001', 'info@lincoln.edu', 'www.lincoln.edu', 'Dr. Sarah Johnson', 1955, 450),
('Washington High School', '456 Learning Ave', 'Madison', 'WI', '53703', '608-555-0002', 'admin@washington.edu', 'www.washington.edu', 'Mr. Michael Chen', 1968, 1200),
('Roosevelt Middle School', '789 Knowledge Blvd', 'Columbus', 'OH', '43215', '614-555-0003', 'contact@roosevelt.edu', 'www.roosevelt.edu', 'Mrs. Lisa Rodriguez', 1975, 800);

-- Insert departments
INSERT INTO departments (school_id, name, description, budget) VALUES
(1, 'Elementary Education', 'Primary education for grades K-5', 250000.00),
(1, 'Special Education', 'Special needs and learning support', 150000.00),
(1, 'Physical Education', 'Sports and physical activities', 75000.00),
(2, 'Mathematics', 'Advanced mathematics education', 180000.00),
(2, 'Science', 'Biology, Chemistry, Physics', 220000.00),
(2, 'English Language Arts', 'Literature and writing', 160000.00),
(2, 'Social Studies', 'History, Geography, Civics', 140000.00),
(2, 'Fine Arts', 'Music, Art, Drama', 120000.00),
(2, 'Physical Education', 'Sports and health education', 100000.00),
(3, 'Core Subjects', 'Math, Science, English, Social Studies', 300000.00),
(3, 'Electives', 'Art, Music, Technology', 150000.00),
(3, 'Special Programs', 'Gifted and Talented, ESL', 100000.00);

-- Insert teachers
INSERT INTO teachers (school_id, department_id, employee_id, first_name, last_name, email, phone, date_of_birth, hire_date, salary, qualification, specialization, is_active) VALUES
-- Lincoln Elementary
(1, 1, 'T001', 'Jennifer', 'Adams', 'j.adams@lincoln.edu', '217-555-1001', '1985-03-15', '2010-08-15', 52000.00, 'MEd Elementary Education', 'Early Childhood', true),
(1, 1, 'T002', 'Robert', 'Williams', 'r.williams@lincoln.edu', '217-555-1002', '1982-07-22', '2008-08-20', 58000.00, 'MEd Elementary Education', '3rd Grade', true),
(1, 1, 'T003', 'Maria', 'Martinez', 'm.martinez@lincoln.edu', '217-555-1003', '1979-11-08', '2005-08-25', 62000.00, 'MEd Elementary Education', '5th Grade', true),
(1, 2, 'T004', 'David', 'Thompson', 'd.thompson@lincoln.edu', '217-555-1004', '1977-01-12', '2003-08-30', 65000.00, 'MEd Special Education', 'Learning Disabilities', true),
(1, 3, 'T005', 'Amanda', 'Clark', 'a.clark@lincoln.edu', '217-555-1005', '1988-09-05', '2015-08-15', 48000.00, 'BS Physical Education', 'Elementary PE', true),

-- Washington High School
(2, 4, 'T006', 'John', 'Anderson', 'j.anderson@washington.edu', '608-555-2001', '1975-04-18', '2000-08-15', 72000.00, 'MS Mathematics', 'Calculus', true),
(2, 4, 'T007', 'Susan', 'Taylor', 's.taylor@washington.edu', '608-555-2002', '1980-06-25', '2005-08-20', 68000.00, 'MS Mathematics', 'Algebra', true),
(2, 5, 'T008', 'Michael', 'Brown', 'm.brown@washington.edu', '608-555-2003', '1978-12-03', '2002-08-25', 75000.00, 'PhD Chemistry', 'Organic Chemistry', true),
(2, 5, 'T009', 'Lisa', 'Davis', 'l.davis@washington.edu', '608-555-2004', '1983-02-14', '2008-08-30', 70000.00, 'MS Biology', 'AP Biology', true),
(2, 6, 'T010', 'Kevin', 'Wilson', 'k.wilson@washington.edu', '608-555-2005', '1981-08-07', '2006-08-15', 66000.00, 'MA English Literature', 'Creative Writing', true),
(2, 7, 'T011', 'Rachel', 'Moore', 'r.moore@washington.edu', '608-555-2006', '1976-05-20', '2001-08-20', 73000.00, 'MA History', 'American History', true),
(2, 8, 'T012', 'Thomas', 'Garcia', 't.garcia@washington.edu', '608-555-2007', '1984-10-12', '2010-08-25', 64000.00, 'MFA Music', 'Band Director', true),

-- Roosevelt Middle School
(3, 10, 'T013', 'Nancy', 'Johnson', 'n.johnson@roosevelt.edu', '614-555-3001', '1979-03-28', '2004-08-15', 59000.00, 'MEd Mathematics', '7th Grade Math', true),
(3, 10, 'T014', 'William', 'Lee', 'w.lee@roosevelt.edu', '614-555-3002', '1982-09-16', '2007-08-20', 61000.00, 'MS Science', '8th Grade Science', true),
(3, 10, 'T015', 'Patricia', 'White', 'p.white@roosevelt.edu', '614-555-3003', '1980-07-04', '2005-08-25', 60000.00, 'MA English', '6th Grade ELA', true),
(3, 11, 'T016', 'James', 'Harris', 'j.harris@roosevelt.edu', '614-555-3004', '1985-01-30', '2012-08-30', 55000.00, 'BFA Art Education', 'Visual Arts', true),
(3, 12, 'T017', 'Linda', 'Martin', 'l.martin@roosevelt.edu', '614-555-3005', '1977-11-22', '2002-08-15', 67000.00, 'MEd ESL', 'English as Second Language', true);

-- Update department heads
UPDATE departments SET head_teacher_id = 1 WHERE id = 1;
UPDATE departments SET head_teacher_id = 4 WHERE id = 2;
UPDATE departments SET head_teacher_id = 6 WHERE id = 4;
UPDATE departments SET head_teacher_id = 8 WHERE id = 5;
UPDATE departments SET head_teacher_id = 10 WHERE id = 6;
UPDATE departments SET head_teacher_id = 13 WHERE id = 10;

-- Insert sample students
INSERT INTO students (school_id, student_id, first_name, last_name, email, phone, date_of_birth, gender, address, city, state, zip_code, parent_name, parent_phone, parent_email, enrollment_date, is_active) VALUES
-- Lincoln Elementary Students
(1, 'S001', 'Emma', 'Johnson', NULL, NULL, '2015-04-12', 'F', '123 Maple St', 'Springfield', 'IL', '62701', 'Mary Johnson', '217-555-4001', 'mary.johnson@email.com', '2021-08-15', true),
(1, 'S002', 'Liam', 'Smith', NULL, NULL, '2014-09-08', 'M', '456 Oak Ave', 'Springfield', 'IL', '62701', 'John Smith', '217-555-4002', 'john.smith@email.com', '2020-08-15', true),
(1, 'S003', 'Olivia', 'Brown', NULL, NULL, '2015-01-22', 'F', '789 Pine Rd', 'Springfield', 'IL', '62701', 'Sarah Brown', '217-555-4003', 'sarah.brown@email.com', '2021-08-15', true),
(1, 'S004', 'Noah', 'Davis', NULL, NULL, '2014-06-15', 'M', '321 Elm St', 'Springfield', 'IL', '62701', 'Michael Davis', '217-555-4004', 'michael.davis@email.com', '2020-08-15', true),
(1, 'S005', 'Sophia', 'Wilson', NULL, NULL, '2015-11-30', 'F', '654 Birch Dr', 'Springfield', 'IL', '62701', 'Lisa Wilson', '217-555-4005', 'lisa.wilson@email.com', '2021-08-15', true),

-- Washington High School Students
(2, 'S006', 'Jackson', 'Miller', 'jackson.miller@student.washington.edu', '608-555-5001', '2007-03-20', 'M', '100 High St', 'Madison', 'WI', '53703', 'Robert Miller', '608-555-5001', 'robert.miller@email.com', '2021-08-15', true),
(2, 'S007', 'Ava', 'Garcia', 'ava.garcia@student.washington.edu', '608-555-5002', '2006-12-05', 'F', '200 College Ave', 'Madison', 'WI', '53703', 'Carmen Garcia', '608-555-5002', 'carmen.garcia@email.com', '2020-08-15', true),
(2, 'S008', 'Lucas', 'Rodriguez', 'lucas.rodriguez@student.washington.edu', '608-555-5003', '2007-08-14', 'M', '300 University Rd', 'Madison', 'WI', '53703', 'Carlos Rodriguez', '608-555-5003', 'carlos.rodriguez@email.com', '2021-08-15', true),
(2, 'S009', 'Isabella', 'Martinez', 'isabella.martinez@student.washington.edu', '608-555-5004', '2006-05-28', 'F', '400 Campus Dr', 'Madison', 'WI', '53703', 'Maria Martinez', '608-555-5004', 'maria.martinez@email.com', '2020-08-15', true),
(2, 'S010', 'Mason', 'Anderson', 'mason.anderson@student.washington.edu', '608-555-5005', '2007-10-11', 'M', '500 School Ln', 'Madison', 'WI', '53703', 'Jennifer Anderson', '608-555-5005', 'jennifer.anderson@email.com', '2021-08-15', true),

-- Roosevelt Middle School Students
(3, 'S011', 'Mia', 'Thomas', 'mia.thomas@student.roosevelt.edu', '614-555-6001', '2010-02-18', 'F', '111 Middle Way', 'Columbus', 'OH', '43215', 'David Thomas', '614-555-6001', 'david.thomas@email.com', '2022-08-15', true),
(3, 'S012', 'Ethan', 'Jackson', 'ethan.jackson@student.roosevelt.edu', '614-555-6002', '2009-07-03', 'M', '222 Junior Blvd', 'Columbus', 'OH', '43215', 'Amanda Jackson', '614-555-6002', 'amanda.jackson@email.com', '2021-08-15', true),
(3, 'S013', 'Charlotte', 'White', 'charlotte.white@student.roosevelt.edu', '614-555-6003', '2010-12-25', 'F', '333 Youth St', 'Columbus', 'OH', '43215', 'Brian White', '614-555-6003', 'brian.white@email.com', '2022-08-15', true),
(3, 'S014', 'Alexander', 'Harris', 'alexander.harris@student.roosevelt.edu', '614-555-6004', '2009-04-16', 'M', '444 Teen Ave', 'Columbus', 'OH', '43215', 'Michelle Harris', '614-555-6004', 'michelle.harris@email.com', '2021-08-15', true),
(3, 'S015', 'Amelia', 'Clark', 'amelia.clark@student.roosevelt.edu', '614-555-6005', '2010-09-09', 'F', '555 Adolescent Rd', 'Columbus', 'OH', '43215', 'Steven Clark', '614-555-6005', 'steven.clark@email.com', '2022-08-15', true);

-- Insert classes
INSERT INTO classes (school_id, name, grade_level, section, academic_year, max_students, room_number) VALUES
-- Lincoln Elementary
(1, 'Kindergarten A', 0, 'A', '2023-24', 20, '101'),
(1, 'First Grade A', 1, 'A', '2023-24', 22, '102'),
(1, 'Second Grade A', 2, 'A', '2023-24', 24, '103'),
(1, 'Third Grade A', 3, 'A', '2023-24', 25, '201'),
(1, 'Fourth Grade A', 4, 'A', '2023-24', 26, '202'),
(1, 'Fifth Grade A', 5, 'A', '2023-24', 28, '203'),

-- Washington High School
(2, 'Freshman Math', 9, 'A', '2023-24', 30, 'M101'),
(2, 'Sophomore Biology', 10, 'A', '2023-24', 28, 'S201'),
(2, 'Junior Chemistry', 11, 'A', '2023-24', 25, 'S202'),
(2, 'Senior Physics', 12, 'A', '2023-24', 22, 'S203'),
(2, 'AP English Literature', 12, 'A', '2023-24', 24, 'E301'),

-- Roosevelt Middle School
(3, 'Sixth Grade A', 6, 'A', '2023-24', 28, '601'),
(3, 'Seventh Grade A', 7, 'A', '2023-24', 30, '701'),
(3, 'Eighth Grade A', 8, 'A', '2023-24', 29, '801');

-- Insert subjects
INSERT INTO subjects (name, code, description, credits, is_mandatory) VALUES
('Mathematics', 'MATH', 'General mathematics education', 1, true),
('Science', 'SCI', 'General science education', 1, true),
('English Language Arts', 'ELA', 'Reading, writing, and literature', 1, true),
('Social Studies', 'SS', 'History, geography, and civics', 1, true),
('Physical Education', 'PE', 'Physical fitness and sports', 1, true),
('Art', 'ART', 'Visual arts and creativity', 1, false),
('Music', 'MUS', 'Music education and appreciation', 1, false),
('Computer Science', 'CS', 'Programming and technology', 1, false),
('Foreign Language', 'FL', 'Second language acquisition', 1, false),
('Health', 'HLTH', 'Health and wellness education', 1, true),
('Biology', 'BIO', 'Study of living organisms', 1, true),
('Chemistry', 'CHEM', 'Study of matter and chemical reactions', 1, true),
('Physics', 'PHYS', 'Study of matter, energy, and motion', 1, false),
('Algebra I', 'ALG1', 'Introductory algebra', 1, true),
('Algebra II', 'ALG2', 'Advanced algebra', 1, true),
('Geometry', 'GEOM', 'Study of shapes and spatial relationships', 1, true),
('Calculus', 'CALC', 'Advanced mathematics', 1, false),
('World History', 'WHIST', 'Global historical perspectives', 1, true),
('US History', 'USHIST', 'American historical studies', 1, true),
('Government', 'GOV', 'Civics and government studies', 1, true);

-- Insert class subjects
INSERT INTO class_subjects (class_id, subject_id, teacher_id, schedule_day, start_time, end_time) VALUES
-- Lincoln Elementary (basic subjects)
(1, 1, 1, 'Monday', '09:00', '09:45'), -- Kindergarten Math
(1, 3, 1, 'Monday', '10:00', '10:45'), -- Kindergarten ELA
(2, 1, 2, 'Tuesday', '09:00', '09:45'), -- First Grade Math
(2, 3, 2, 'Tuesday', '10:00', '10:45'), -- First Grade ELA
(6, 1, 3, 'Wednesday', '09:00', '09:45'), -- Fifth Grade Math
(6, 3, 3, 'Wednesday', '10:00', '10:45'), -- Fifth Grade ELA

-- Washington High School
(7, 14, 6, 'Monday', '08:00', '08:50'), -- Freshman Algebra I
(8, 11, 9, 'Monday', '09:00', '09:50'), -- Sophomore Biology
(9, 12, 8, 'Tuesday', '10:00', '10:50'), -- Junior Chemistry
(10, 13, 8, 'Tuesday', '11:00', '11:50'), -- Senior Physics
(11, 3, 10, 'Wednesday', '13:00', '13:50'), -- AP English

-- Roosevelt Middle School
(12, 1, 13, 'Monday', '08:30', '09:20'), -- Sixth Grade Math
(13, 1, 13, 'Tuesday', '08:30', '09:20'), -- Seventh Grade Math
(14, 2, 14, 'Wednesday', '09:30', '10:20'); -- Eighth Grade Science

-- Insert student enrollments
INSERT INTO student_enrollments (student_id, class_id, enrollment_date, status) VALUES
-- Lincoln Elementary
(1, 6, '2023-08-15', 'active'), -- Emma in 5th grade
(2, 5, '2023-08-15', 'active'), -- Liam in 4th grade
(3, 6, '2023-08-15', 'active'), -- Olivia in 5th grade
(4, 5, '2023-08-15', 'active'), -- Noah in 4th grade
(5, 6, '2023-08-15', 'active'), -- Sophia in 5th grade

-- Washington High School
(6, 7, '2023-08-15', 'active'), -- Jackson in Freshman Math
(7, 8, '2023-08-15', 'active'), -- Ava in Sophomore Biology
(8, 7, '2023-08-15', 'active'), -- Lucas in Freshman Math
(9, 8, '2023-08-15', 'active'), -- Isabella in Sophomore Biology
(10, 7, '2023-08-15', 'active'), -- Mason in Freshman Math

-- Roosevelt Middle School
(11, 12, '2023-08-15', 'active'), -- Mia in 6th grade
(12, 13, '2023-08-15', 'active'), -- Ethan in 7th grade
(13, 12, '2023-08-15', 'active'), -- Charlotte in 6th grade
(14, 13, '2023-08-15', 'active'), -- Alexander in 7th grade
(15, 12, '2023-08-15', 'active'); -- Amelia in 6th grade

-- Insert exams
INSERT INTO exams (subject_id, class_id, teacher_id, exam_name, exam_type, exam_date, max_marks, duration_minutes, description) VALUES
(1, 6, 3, 'Mid-term Math Assessment', 'midterm', '2023-10-15', 100, 60, 'Comprehensive math evaluation for 5th grade'),
(3, 6, 3, 'Reading Comprehension Test', 'quiz', '2023-09-20', 50, 30, 'Reading skills assessment'),
(14, 7, 6, 'Algebra I Mid-term', 'midterm', '2023-10-20', 100, 90, 'Mid-semester algebra evaluation'),
(11, 8, 9, 'Biology Chapter 3 Quiz', 'quiz', '2023-09-25', 25, 45, 'Cellular biology assessment'),
(12, 9, 8, 'Chemistry Lab Practical', 'practical', '2023-11-10', 75, 120, 'Hands-on chemistry lab examination'),
(1, 12, 13, '6th Grade Math Unit Test', 'test', '2023-09-30', 80, 50, 'Fractions and decimals unit assessment'),
(2, 14, 14, '8th Grade Science Project', 'project', '2023-11-15', 100, 0, 'Independent science research project');

-- Insert student grades
INSERT INTO student_grades (student_id, exam_id, marks_obtained, grade, remarks) VALUES
-- 5th Grade Math Mid-term
(1, 1, 87.5, 'B+', 'Good understanding of concepts'),
(3, 1, 92.0, 'A-', 'Excellent work'),
(5, 1, 78.5, 'C+', 'Needs improvement in word problems'),

-- 5th Grade Reading Quiz
(1, 2, 45.0, 'A', 'Excellent reading comprehension'),
(3, 2, 42.0, 'A-', 'Very good analysis'),
(5, 2, 38.0, 'B+', 'Good understanding'),

-- Freshman Algebra Mid-term
(6, 3, 85.0, 'B', 'Solid algebraic understanding'),
(8, 3, 91.5, 'A-', 'Excellent problem-solving skills'),
(10, 3, 76.0, 'C+', 'Needs more practice with factoring'),

-- Biology Quiz
(7, 4, 23.0, 'A-', 'Great knowledge of cell structure'),
(9, 4, 21.5, 'B+', 'Good understanding of processes'),

-- Chemistry Lab Practical
-- (No grades yet as exam is in future)

-- 6th Grade Math Unit Test
(11, 6, 72.0, 'B-', 'Good progress with fractions'),
(13, 6, 68.5, 'C+', 'Needs more practice with decimals'),
(15, 6, 75.5, 'B', 'Solid understanding of concepts');

-- Insert attendance records (last 30 days)
INSERT INTO attendance (student_id, class_id, date, status, remarks) VALUES
-- Sample attendance for some students over recent dates
(1, 6, '2024-01-15', 'present', NULL),
(1, 6, '2024-01-16', 'present', NULL),
(1, 6, '2024-01-17', 'absent', 'Sick'),
(1, 6, '2024-01-18', 'present', NULL),
(1, 6, '2024-01-19', 'present', NULL),

(6, 7, '2024-01-15', 'present', NULL),
(6, 7, '2024-01-16', 'late', 'Bus delay'),
(6, 7, '2024-01-17', 'present', NULL),
(6, 7, '2024-01-18', 'present', NULL),
(6, 7, '2024-01-19', 'present', NULL),

(11, 12, '2024-01-15', 'present', NULL),
(11, 12, '2024-01-16', 'present', NULL),
(11, 12, '2024-01-17', 'present', NULL),
(11, 12, '2024-01-18', 'excused', 'Doctor appointment'),
(11, 12, '2024-01-19', 'present', NULL);
EOF

    log "Sample data files generated"
}

# Execute SQL files in PostgreSQL
execute_sql_files() {
    log "Executing SQL files..."
    
    # Food Delivery Database
    info "Setting up Food Delivery Database..."
    docker exec -i "$CONTAINER_NAME" psql -U "$POSTGRES_USER" -d "$FOOD_DB_NAME" < /tmp/postgres_seed/food_delivery_schema.sql
    docker exec -i "$CONTAINER_NAME" psql -U "$POSTGRES_USER" -d "$FOOD_DB_NAME" < /tmp/postgres_seed/food_delivery_data.sql
    
    # School Management Database
    info "Setting up School Management Database..."
    docker exec -i "$CONTAINER_NAME" psql -U "$POSTGRES_USER" -d "$SCHOOL_DB_NAME" < /tmp/postgres_seed/school_management_schema.sql
    docker exec -i "$CONTAINER_NAME" psql -U "$POSTGRES_USER" -d "$SCHOOL_DB_NAME" < /tmp/postgres_seed/school_management_data.sql
    
    log "Database setup completed successfully"
}

# Generate database documentation
generate_documentation() {
    log "Generating database documentation..."
    
    cat > /tmp/postgres_seed/DATABASE_DOCUMENTATION.md << 'EOF'
# PostgreSQL Multi-Database Documentation

## Overview
This PostgreSQL instance contains two fully seeded databases designed for real-world application development and testing.

## Database Connection Information
- **Host**: localhost
- **Port**: 5432
- **Username**: postgres
- **Password**: admin123
- **Container Name**: postgres_multidb

## Databases

### 1. Food Delivery Database (`food_delivery_db`)

A comprehensive database for a food delivery application with realistic data for 100+ records across multiple entities.

#### Tables and Data Counts:
- **users** (10 records): Customer accounts with authentication details
- **addresses** (10 records): User delivery addresses
- **restaurants** (10 records): Restaurant profiles with cuisine types and ratings
- **menu_categories** (15 records): Organized menu sections
- **menu_items** (26 records): Individual food items with pricing and dietary info
- **orders** (10 records): Order history with various statuses
- **order_items** (15 records): Detailed order line items
- **reviews** (8 records): Customer feedback and ratings

#### Key Features:
- Complete order lifecycle (pending → confirmed → preparing → delivered)
- Restaurant rating system (1-5 stars)
- Menu categorization with dietary restrictions
- Payment processing with multiple methods
- Delivery tracking and timing
- Customer review system

#### Sample Queries:
```sql
-- Get top-rated restaurants
SELECT name, cuisine_type, rating FROM restaurants ORDER BY rating DESC LIMIT 5;

-- Find popular menu items
SELECT mi.name, COUNT(oi.id) as order_count 
FROM menu_items mi 
JOIN order_items oi ON mi.id = oi.menu_item_id 
GROUP BY mi.id, mi.name 
ORDER BY order_count DESC;

-- Calculate restaurant revenue
SELECT r.name, SUM(o.total_amount) as revenue 
FROM restaurants r 
JOIN orders o ON r.id = o.restaurant_id 
WHERE o.status = 'delivered' 
GROUP BY r.id, r.name;
```

### 2. School Management Database (`school_management_db`)

A complete school administration system with realistic academic data across multiple schools.

#### Tables and Data Counts:
- **schools** (3 records): Elementary, Middle, and High School
- **departments** (12 records): Academic departments with budgets
- **teachers** (17 records): Faculty with qualifications and salaries
- **students** (15 records): Student profiles across all grade levels
- **classes** (14 records): Grade-level classes and sections
- **subjects** (20 records): Academic subjects and courses
- **class_subjects** (9 records): Class schedules and teacher assignments
- **student_enrollments** (15 records): Student class registrations
- **exams** (7 records): Various assessment types
- **student_grades** (12 records): Academic performance data
- **attendance** (15 records): Daily attendance tracking

#### Key Features:
- Multi-school system (Elementary, Middle, High School)
- Department hierarchy with head teachers
- Complete academic calendar and scheduling
- Grade tracking and GPA calculations
- Attendance monitoring
- Teacher qualification and salary management
- Parent contact information
- Student enrollment history

#### Sample Queries:
```sql
-- Get student GPA
SELECT s.first_name, s.last_name, AVG(sg.marks_obtained) as avg_score
FROM students s
JOIN student_grades sg ON s.id = sg.student_id
GROUP BY s.id, s.first_name, s.last_name;

-- Find teachers by department
SELECT d.name as department, t.first_name, t.last_name, t.specialization
FROM teachers t
JOIN departments d ON t.department_id = d.id
ORDER BY d.name, t.last_name;

-- Get class schedules
SELECT c.name, s.name as subject, t.first_name, t.last_name, 
       cs.schedule_day, cs.start_time, cs.end_time
FROM classes c
JOIN class_subjects cs ON c.id = cs.class_id
JOIN subjects s ON cs.subject_id = s.id
JOIN teachers t ON cs.teacher_id = t.id
ORDER BY c.name, cs.schedule_day, cs.start_time;

-- Check attendance rates
SELECT s.first_name, s.last_name,
       COUNT(CASE WHEN a.status = 'present' THEN 1 END) as present_days,
       COUNT(*) as total_days,
       ROUND(COUNT(CASE WHEN a.status = 'present' THEN 1 END) * 100.0 / COUNT(*), 2) as attendance_rate
FROM students s
JOIN attendance a ON s.id = a.student_id
GROUP BY s.id, s.first_name, s.last_name;
```

## Data Relationships

### Food Delivery Database ERD:
```
users (1) ──── (M) addresses
users (1) ──── (M) orders ──── (M) restaurants
orders (1) ──── (M) order_items ──── (M) menu_items
restaurants (1) ──── (M) menu_categories ──── (M) menu_items
users (1) ──── (M) reviews ──── (M) restaurants
```

### School Management Database ERD:
```
schools (1) ──── (M) departments ──── (M) teachers
schools (1) ──── (M) students
schools (1) ──── (M) classes
classes (M) ──── (M) subjects (via class_subjects)
students (M) ──── (M) classes (via student_enrollments)
students (1) ──── (M) student_grades ──── (M) exams
students (1) ──── (M) attendance
```

## Getting Started

### Connect to the databases:
```bash
# Food Delivery Database
docker exec -it postgres_multidb psql -U postgres -d food_delivery_db

# School Management Database
docker exec -it postgres_multidb psql -U postgres -d school_management_db
```

### Useful PostgreSQL Commands:
```sql
-- List all databases
\l

-- Connect to a database
\c database_name

-- List all tables
\dt

-- Describe a table structure
\d table_name

-- Show table with sample data
SELECT * FROM table_name LIMIT 5;
```

## Backup and Restore

### Create Backups:
```bash
# Backup Food Delivery Database
docker exec postgres_multidb pg_dump -U postgres food_delivery_db > food_delivery_backup.sql

# Backup School Management Database
docker exec postgres_multidb pg_dump -U postgres school_management_db > school_management_backup.sql
```

### Restore from Backup:
```bash
# Restore Food Delivery Database
docker exec -i postgres_multidb psql -U postgres -d food_delivery_db < food_delivery_backup.sql

# Restore School Management Database
docker exec -i postgres_multidb psql -U postgres -d school_management_db < school_management_backup.sql
```

## Performance Optimization

Both databases include optimized indexes for common queries:
- Primary keys and foreign keys
- Frequently searched columns (email, student_id, order_status)
- Date columns for time-based queries
- Rating and performance metrics

## Security Considerations

- Default password is set to 'admin123' - change in production
- User emails are realistic but fictional
- Phone numbers use standard xxx-xxx-xxxx format
- All sensitive data is appropriately hashed/encrypted where applicable

## Additional Features

### Food Delivery Database:
- Multi-cuisine restaurant support
- Dietary restriction tracking (vegetarian, vegan)
- Order status workflow
- Delivery fee calculation
- Customer review system

### School Management Database:
- Multi-grade level support (K-12)
- Teacher qualification tracking
- Academic year management
- Attendance status varieties
- Grade point calculations
- Department budget tracking

---

*Generated by PostgreSQL Multi-Database Setup Script*
*Last Updated: $(date)*
EOF

    log "Documentation generated at /tmp/postgres_seed/DATABASE_DOCUMENTATION.md"
}

# Cleanup function
cleanup() {
    log "Cleaning up temporary files..."
    rm -rf /tmp/postgres_seed
}

# Display connection information
show_connection_info() {
    log "PostgreSQL Multi-Database Setup Complete!"
    echo
    echo -e "${BLUE}=== CONNECTION INFORMATION ===${NC}"
    echo -e "${GREEN}Host:${NC} localhost"
    echo -e "${GREEN}Port:${NC} $DB_PORT"
    echo -e "${GREEN}Username:${NC} $POSTGRES_USER"
    echo -e "${GREEN}Password:${NC} $POSTGRES_PASSWORD"
    echo -e "${GREEN}Container:${NC} $CONTAINER_NAME"
    echo
    echo -e "${BLUE}=== DATABASES ===${NC}"
    echo -e "${GREEN}1. Food Delivery:${NC} $FOOD_DB_NAME"
    echo -e "${GREEN}2. School Management:${NC} $SCHOOL_DB_NAME"
    echo
    echo -e "${BLUE}=== QUICK CONNECT ===${NC}"
    echo -e "${YELLOW}Food Delivery DB:${NC}"
    echo "docker exec -it $CONTAINER_NAME psql -U $POSTGRES_USER -d $FOOD_DB_NAME"
    echo
    echo -e "${YELLOW}School Management DB:${NC}"
    echo "docker exec -it $CONTAINER_NAME psql -U $POSTGRES_USER -d $SCHOOL_DB_NAME"
    echo
    echo -e "${BLUE}=== DOCUMENTATION ===${NC}"
    echo "Complete documentation available at: /tmp/postgres_seed/DATABASE_DOCUMENTATION.md"
    echo
    echo -e "${GREEN}Setup completed successfully!${NC}"
}

# Error handling
handle_error() {
    error "Script failed at line $1"
    cleanup
    exit 1
}

trap 'handle_error $LINENO' ERR

# Main execution
main() {
    log "Starting PostgreSQL Multi-Database Setup..."
    
    check_docker
    cleanup_existing
    start_postgres
    create_databases
    generate_fake_data
    generate_sample_data
    execute_sql_files
    generate_documentation
    show_connection_info
    
    log "All operations completed successfully!"
}

# Execute main function
main "$@"