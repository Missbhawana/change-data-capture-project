require("dotenv").config();
const express = require("express");
const { connectDB } = require("./config/database");
const { setupCDC } = require("./services/cdcService");
const apiRoutes = require("./routes/api");

const app = express();
app.use(express.json());

// API Routes
app.use("/api", apiRoutes);

const PORT = process.env.PORT || 3000;

async function startServer() {
  try {
    // 1. Connect to MongoDB
    await connectDB();
    console.log("Connected to MongoDB successfully.");

    // 2. Set up CDC Change Streams
    setupCDC();

    // 3. Start Express server
    app.listen(PORT, () => {
      console.log(`Server is running on http://localhost:${PORT}`);
    });
  } catch (error) {
    console.error("Failed to start server:", error);
    process.exit(1);
  }
}

startServer();
