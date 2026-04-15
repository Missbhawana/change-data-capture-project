const { MongoMemoryReplSet } = require('mongodb-memory-server');
const path = require('path');

async function runWithMemoryDB() {
  console.log('[System] Starting In-Memory MongoDB Replica Set...');
  
  // Create an in-memory replica set
  const replSet = await MongoMemoryReplSet.create({ replSet: { count: 1 } });
  const uri = replSet.getUri();
  
  console.log(`[System] In-Memory MongoDB running at: ${uri}`);
  
  // Override the environment variable so the original code connects here
  process.env.MONGODB_URI = uri;
  process.env.MONGODB_DB_NAME = 'cdc_demo';

  // Import and run the actual server
  require('./src/server.js');
}

runWithMemoryDB().catch(err => {
  console.error('[System] Failed to start In-Memory Database:', err);
  process.exit(1);
});
