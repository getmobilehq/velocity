-- Create database
CREATE DATABASE velocity;

-- Use the database
\c velocity;

-- Users Table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    fullname TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    role TEXT CHECK(role IN ('admin', 'sales', 'manager')) DEFAULT 'sales',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Leads Table
CREATE TABLE leads (
    phone TEXT PRIMARY KEY,
    fullname TEXT NOT NULL,
    course TEXT NOT NULL,
    status TEXT CHECK(status IN ('New Lead', 'Engaged Lead', 'Qualified Lead', 'Converted', 'Inactive')),
    payment_status TEXT CHECK(payment_status IN ('Not Paid', 'Paid')),
    decision TEXT CHECK(decision IN ('Still Interested', 'Next Cohort', 'Not Interested')),
    last_message_time TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Conversations Table
CREATE TABLE conversations (
    id SERIAL PRIMARY KEY,
    lead_phone TEXT REFERENCES leads(phone) ON DELETE CASCADE,
    message TEXT NOT NULL,
    direction TEXT CHECK(direction IN ('sent', 'received')),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
