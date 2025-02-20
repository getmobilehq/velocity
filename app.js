// Import required modules
const express = require("express");
const cors = require("cors");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcrypt");
const { PrismaClient } = require("@prisma/client");
const dotenv = require("dotenv");

// Load environment variables
dotenv.config();

const app = express();
const prisma = new PrismaClient();

// Middleware
app.use(cors());
app.use(express.json());

// JWT Middleware
const authenticateToken = (req, res, next) => {
    const token = req.header("Authorization");
    if (!token) return res.status(401).json({ message: "Access Denied" });

    jwt.verify(token.split(" ")[1], process.env.JWT_SECRET, (err, user) => {
        if (err) return res.status(403).json({ message: "Invalid Token" });
        req.user = user;
        next();
    });
};

// Role-based Access Middleware
const authorizeRoles = (...roles) => {
    return (req, res, next) => {
        if (!roles.includes(req.user.role)) {
            return res.status(403).json({ message: "Access Denied" });
        }
        next();
    };
};

// User Registration (Admin Only)
app.post("/auth/register", authenticateToken, authorizeRoles("admin"), async (req, res) => {
    const { fullname, email, password, role } = req.body;
    const hashedPassword = await bcrypt.hash(password, 10);
    try {
        const user = await prisma.user.create({
            data: { fullname, email, password: hashedPassword, role },
        });
        res.status(201).json(user);
    } catch (error) {
        res.status(400).json({ message: "User already exists" });
    }
});

// User Login
app.post("/auth/login", async (req, res) => {
    const { email, password } = req.body;
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user || !(await bcrypt.compare(password, user.password))) {
        return res.status(401).json({ message: "Invalid credentials" });
    }
    const token = jwt.sign({ id: user.id, role: user.role }, process.env.JWT_SECRET, { expiresIn: "1d" });
    res.json({ token, user });
});

// Fetch all Users (Admin Only)
app.get("/users", authenticateToken, authorizeRoles("admin"), async (req, res) => {
    const users = await prisma.user.findMany();
    res.json(users);
});

// CRUD for Leads
app.post("/leads", authenticateToken, async (req, res) => {
    const lead = await prisma.lead.create({ data: req.body });
    res.status(201).json(lead);
});

app.get("/leads", authenticateToken, async (req, res) => {
    const leads = await prisma.lead.findMany();
    res.json(leads);
});

app.get("/leads/:phone", authenticateToken, async (req, res) => {
    const lead = await prisma.lead.findUnique({ where: { phone: req.params.phone } });
    res.json(lead);
});

app.put("/leads/:phone", authenticateToken, async (req, res) => {
    const lead = await prisma.lead.update({ where: { phone: req.params.phone }, data: req.body });
    res.json(lead);
});

app.delete("/leads/:phone", authenticateToken, authorizeRoles("admin"), async (req, res) => {
    await prisma.lead.delete({ where: { phone: req.params.phone } });
    res.json({ message: "Lead deleted" });
});

// Start Server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
