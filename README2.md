# Building the Change Data Capture (CDC) System: Step-by-Step Guide

This document outlines the exact steps taken to construct this complete CDC project from scratch, including the installation of system dependencies and the programmatic setup of the Node.js backend and MongoDB Replica Set.

---

## Part 1: Prerequisites & System Dependencies

To capture real-time changes, MongoDB requires a feature called **Change Streams**, which is only available when MongoDB is running as a **Replica Set**.

### 1. Install Node.js and MongoDB
We used the Windows Package Manager (`winget`) to install the core technologies system-wide.
```powershell
winget install --id OpenJS.NodeJS.LTS -e
winget install --id MongoDB.Server -e
winget install --id MongoDB.Shell -e
```

### 2. Initialize the MongoDB Replica Set
A standalone MongoDB instance cannot emit Change Streams. We started the MongoDB daemon (`mongod`) specifically with the `--replSet rs0` flag and pointed it to a local data directory.
```powershell
mkdir mdbata
"C:\Program Files\MongoDB\Server\8.2\bin\mongod.exe" --dbpath="mdbata" --replSet rs0
```

Once running, we had to initialize the replica set using the MongoDB Node.js Driver (or `mongosh`):
```javascript
// Programmatic initialization used during setup:
MongoClient.connect('mongodb://127.0.0.1:27017/admin', {directConnection: true})
  .then(client => client.db('admin').command({
      replSetInitiate: { _id: 'rs0', members: [{ _id: 0, host: '127.0.0.1:27017' }] }
  }));
```

---

## Part 2: Project Initialization & Configuration

### 3. Initialize the Node.js Project
We created the `package.json` to manage our dependencies (`express`, `mongodb`, `dotenv`).
```bash
npm init -y
npm install express mongodb dotenv
```

### 4. Setup Configuration Files
We created two configuration files to manage the application state:
1.  **`.env`**: Stores the port and MongoDB connection string (`mongodb://127.0.0.1:27017/cdc_demo`).
2.  **`config/app-config.json`**: Stores the debouncing logic configuration (e.g., `"debounceIntervalMs": 5000`).

---

## Part 3: Backend Implementation

We modularized the backend into distinct responsibilities: Database Connection, CDC Listening, Debouncing, and API exposure.

### 5. MongoDB Connection (`src/config/database.js`)
We created a reusable connection pool using the official `mongodb` package to connect to our local Replica Set.

### 6. The Debounce Service (`src/services/debounceService.js`)
To prevent overwhelming target systems when thousands of database mutations happen per second, we implemented a buffering system.
*   It traps incoming events into a memory array.
*   It starts a countdown timer (`setTimeout`).
*   If new events arrive, the timer resets until a "quiet period" occurs.
*   Once the timer successfully counts down to 0, it wraps the events in a batch and dispatches them.

### 7. The CDC Service (`src/services/cdcService.js`)
This is the core engine. We connected to the target collection (`users`) and invoked the `.watch()` method.
```javascript
const changeStream = collection.watch([], { fullDocument: 'updateLookup' });
changeStream.on("change", (changeEvent) => {
    debounceService.addEvent(changeEvent);
});
```
This listener natively hooks into the MongoDB oplog to emit `insert`, `update`, and `delete` payloads instantly.

### 8. The Express API (`src/server.js`, `src/routes/api.js`, `src/controllers/eventController.js`)
We wrapped the system in an Express server on Port 3000. 
*   Added `GET /api/status` to monitor the size of the debounce buffer in real-time.
*   Added `GET /api/batches` to retrieve historical batches of processed CDC payloads.
*   Added `POST /api/simulate` to allow bypassing MongoDB entirely for isolated testing.

---

## Part 4: Shell Scripts & System Architecture

### 9. System File Monitoring (`scripts/monitor-config.sh`)
To satisfy the Linux `inotify` requirement, we created a bash script utilizing `inotifywait` to actively watch the `app-config.json` file for modifications. When a write operation is detected on the config file, the script signals the backend to reload the debounce intervals without taking the server offline. *(Note: Must run in WSL on Windows).*

### 10. Data Transformation Pipeline (`scripts/filter-data.sh`)
CDC payloads contain raw internal MongoDB metadata and sensitive document fields. We wrote a sample Unix pipeline (`grep`, `awk`, `sed`) to demonstrate how an external service sweeps the JSON payloads, extracts just the Operation Types, and redacts sensitive parameters like passwords before they reach an analytics warehouse.

## Conclusion
By combining the low-level oplog features of a MongoDB Replica Set with the asynchronous non-blocking event loop of Node.js, we orchestrated a highly efficient CDC pipeline capable of smoothing out high-velocity traffic spikes via in-memory debouncing.
