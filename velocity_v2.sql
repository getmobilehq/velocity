-- Drop tables if they exist (for clean setup)
DROP TABLE IF EXISTS Conversations;
DROP TABLE IF EXISTS BotMessages;
DROP TABLE IF EXISTS Leads;
DROP TABLE IF EXISTS Courses;
DROP TABLE IF EXISTS Users;

-- Table 1: Users
-- Stores admin and sales team credentials for authentication
CREATE TABLE Users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,       -- e.g., "admin1", "sales1"
    password VARCHAR(255) NOT NULL,             -- Hashed password (e.g., bcrypt)
    role ENUM('admin', 'sales') NOT NULL,       -- e.g., "admin" or "sales"
    email VARCHAR(100) UNIQUE NOT NULL,         -- e.g., "admin@example.com"
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username),              -- For fast login lookups
    INDEX idx_role (role)                       -- For role-based filtering
);

-- Table 2: Courses
-- Stores course details for dynamic insertion
CREATE TABLE Courses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,                 -- e.g., "COURSE1"
    start_date DATE NOT NULL,                   -- e.g., "2025-03-01"
    payment_link VARCHAR(255) NOT NULL,         -- e.g., "payment.link/course1"
    access_link VARCHAR(255),                   -- e.g., "course1.access.link"
    INDEX idx_name (name)                       -- For quick lookups by course name
);

-- Table 3: Leads
-- Stores lead data and state
CREATE TABLE Leads (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone VARCHAR(15) UNIQUE NOT NULL,          -- e.g., "+1234567890"
    fullname VARCHAR(100) NOT NULL,             -- e.g., "John Doe"
    course_id INT,                              -- Foreign key to Courses (NULL until selected)
    status ENUM('New Lead', 'Engaged Lead', 'Qualified Lead', 'Converted', 'Inactive') DEFAULT 'New Lead',
    payment_status ENUM('Not Paid', 'Paid') DEFAULT 'Not Paid',
    decision ENUM('Still Interested', 'Next Cohort', 'Not Interested') DEFAULT 'Still Interested',
    last_message_time DATETIME,                 -- For follow-up timing
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (course_id) REFERENCES Courses(id),
    INDEX idx_phone_status (phone, status),     -- For API/bot queries
    INDEX idx_decision (decision)               -- For dashboard filtering
);

-- Table 4: Conversations
-- Logs all messages for each lead
CREATE TABLE Conversations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    lead_id INT NOT NULL,                       -- Foreign key to Leads
    message TEXT NOT NULL,                      -- e.g., "Hi John, thanks for your interest!"
    direction ENUM('sent', 'received') NOT NULL,-- e.g., "sent" or "received"
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (lead_id) REFERENCES Leads(id) ON DELETE CASCADE,
    INDEX idx_lead_id (lead_id)                 -- For quick message history retrieval
);

-- Table 5: BotMessages
-- Feeds bot responses based on status and decision
CREATE TABLE BotMessages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    status ENUM('New Lead', 'Engaged Lead', 'Qualified Lead', 'Converted', 'Inactive') NOT NULL,
    decision ENUM('Still Interested', 'Next Cohort', 'Not Interested') NOT NULL,
    trigger VARCHAR(50),                        -- e.g., "COURSE1", "JOIN", "FOLLOWUP"
    message TEXT NOT NULL,                      -- e.g., "Hi [FULLNAME], thanks for your interest!"
    days_after INT DEFAULT 0,                   -- 0 (immediate), >0 (follow-up delay)
    next_status ENUM('New Lead', 'Engaged Lead', 'Qualified Lead', 'Converted', 'Inactive') DEFAULT NULL,
    next_decision ENUM('Still Interested', 'Next Cohort', 'Not Interested') DEFAULT NULL,
    INDEX idx_status_decision (status, decision, trigger)  -- For fast bot lookups
);

-- Sample Data for Users
INSERT INTO Users (username, password, role, email) VALUES
('admin1', '$2b$10$examplehashedpassword123', 'admin', 'admin1@example.com'), -- Password: "adminpass" (hashed)
('sales1', '$2b$10$examplehashedpassword456', 'sales', 'sales1@example.com'); -- Password: "salespass" (hashed)

-- Sample Data for Courses
INSERT INTO Courses (name, start_date, payment_link, access_link) VALUES
('COURSE1', '2025-03-01', 'payment.link/course1', 'course1.access.link'),
('COURSE2', '2025-03-15', 'payment.link/course2', 'course2.access.link');

-- Sample Data for BotMessages
INSERT INTO BotMessages (status, decision, trigger, message, days_after, next_status, next_decision) VALUES
-- New Lead / Still Interested
('New Lead', 'Still Interested', NULL, 'Hi [FULLNAME], thanks for your interest! Reply with a course: ‘COURSE1’, ‘COURSE2’, or ‘LIST’.', 0, NULL, NULL),
('New Lead', 'Still Interested', 'COURSE1', 'Great choice, [FULLNAME]! [Course Name] starts [Start Date]. Reply ‘INFO’ or ‘JOIN’.', 0, 'Engaged Lead', NULL),
('New Lead', 'Still Interested', 'COURSE2', 'Great choice, [FULLNAME]! [Course Name] starts [Start Date]. Reply ‘INFO’ or ‘JOIN’.', 0, 'Engaged Lead', NULL),
('New Lead', 'Still Interested', 'LIST', 'Courses: 1) COURSE1 - 2025-03-01, 2) COURSE2 - 2025-03-15. Reply ‘COURSE1’ or ‘COURSE2’.', 0, NULL, NULL),
('New Lead', 'Still Interested', 'FOLLOWUP', 'Hey [FULLNAME], still there? Reply ‘COURSE1’, ‘COURSE2’, or ‘LIST’!', 1, NULL, NULL),

-- Engaged Lead / Still Interested
('Engaged Lead', 'Still Interested', NULL, 'Hi [FULLNAME], excited for [Course Name]? Reply ‘INFO’ or ‘JOIN’.', 0, NULL, NULL),
('Engaged Lead', 'Still Interested', 'INFO', 'Here’s [Course Name]: [Key Benefit]. Ready? Reply ‘JOIN’.', 0, NULL, NULL),
('Engaged Lead', 'Still Interested', 'JOIN', 'Awesome, [FULLNAME]! Secure your spot: [Payment Link]. Reply ‘PAID’ or ‘ASK’.', 0, 'Qualified Lead', NULL),
('Engaged Lead', 'Still Interested', 'ASK', 'What’s up, [FULLNAME]? Reply with your question!', 0, NULL, NULL),
('Engaged Lead', 'Still Interested', 'FOLLOWUP', 'Hi [FULLNAME], [Course Name] starts [Start Date]—only [X] spots left! Reply ‘JOIN’.', 3, NULL, NULL),

-- Qualified Lead / Still Interested
('Qualified Lead', 'Still Interested', NULL, 'Hi [FULLNAME], ready to join [Course Name]? Pay here: [Payment Link]. Reply ‘PAID’.', 0, NULL, NULL),
('Qualified Lead', 'Still Interested', 'PAID', 'You’re in, [FULLNAME]! Access [Course Name] here: [Access Link].', 0, 'Converted', 'Not Interested'),
('Qualified Lead', 'Still Interested', 'NEXT', 'Got it, [FULLNAME]! We’ll notify you for the next [Course Name] cohort.', 0, NULL, 'Next Cohort'),
('Qualified Lead', 'Still Interested', 'ASK', 'What’s up, [FULLNAME]? Reply with your question!', 0, NULL, NULL),
('Qualified Lead', 'Still Interested', 'FOLLOWUP', 'Last chance, [FULLNAME]! [Course Name] starts [Start Date]. Pay: [Payment Link] or reply ‘NEXT’.', 7, NULL, NULL),

-- Converted / Not Interested
('Converted', 'Not Interested', NULL, 'Welcome back, [FULLNAME]! Your [Course Name] access: [Access Link].', 0, NULL, NULL),

-- Inactive / Still Interested
('Inactive', 'Still Interested', NULL, 'Hi [FULLNAME], still interested? Reply ‘YES’ or ‘NEXT’.', 0, NULL, NULL),
('Inactive', 'Still Interested', 'YES', 'Great! Join [Course Name]: [Payment Link]. Reply ‘PAID’.', 0, 'Qualified Lead', NULL),
('Inactive', 'Still Interested', 'NEXT', 'Got it, [FULLNAME]! We’ll notify you for the next cohort.', 0, NULL, 'Next Cohort'),
('Inactive', 'Still Interested', 'FOLLOWUP', 'Hey [FULLNAME], still with us? Reply ‘YES’ or ‘NEXT’.', 10, NULL, NULL),

-- Any Status / Next Cohort (Consolidated)
('New Lead', 'Next Cohort', NULL, 'Got it, [FULLNAME]! We’ll notify you for the next cohort.', 0, NULL, NULL),
('Engaged Lead', 'Next Cohort', NULL, 'Got it, [FULLNAME]! We’ll notify you for the next [Course Name] cohort.', 0, NULL, NULL),
('Qualified Lead', 'Next Cohort', NULL, 'Got it, [FULLNAME]! We’ll notify you for the next [Course Name] cohort.', 0, NULL, NULL),
('Inactive', 'Next Cohort', NULL, 'Got it, [FULLNAME]! We’ll notify you for the next cohort.', 0, NULL, NULL),

-- Any Status / Not Interested (Consolidated)
('New Lead', 'Not Interested', NULL, 'Thanks for checking us out, [FULLNAME]!', 0, NULL, NULL),
('Engaged Lead', 'Not Interested', NULL, 'Thanks for your interest, [FULLNAME]!', 0, NULL, NULL),
('Qualified Lead', 'Not Interested', NULL, 'Thanks for considering us, [FULLNAME]!', 0, NULL, NULL),
('Inactive', 'Not Interested', NULL, 'Take care, [FULLNAME]!', 0, NULL, NULL);

-- Sample Lead for Testing
INSERT INTO Leads (phone, fullname, status, payment_status, decision) VALUES
('+1234567890', 'Sarah Lee', 'New Lead', 'Not Paid', 'Still Interested');
