const http = require('http');

async function testBackend() {
  // 1. Start server on test port 3099
  process.env.PORT = '3099';
  process.env.GEMINI_API_KEY = ''; // test unconfigured behavior
  const server = require('./server.js');

  await new Promise((r) => setTimeout(r, 800));

  console.log('Testing /health endpoint on port 3099...');

  const healthRes = await fetch('http://localhost:3099/health');
  const healthData = await healthRes.json();
  console.log('Health Response:', healthData);

  if (healthData.status !== 'ok') {
    throw new Error('Health check failed: ' + JSON.stringify(healthData));
  }

  console.log('Testing /api/chat unconfigured error handling...');
  const chatRes = await fetch('http://localhost:3099/api/chat', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ message: 'What is an index fund?' }),
  });
  const chatData = await chatRes.json();
  console.log('Chat Response (Status ' + chatRes.status + '):', chatData);

  if (chatRes.status !== 503 || !chatData.setupRequired) {
    throw new Error('Expected 503 Backend Unconfigured response');
  }

  console.log('All backend proxy tests passed successfully! ✅');
  process.exit(0);
}

testBackend().catch((err) => {
  console.error('Backend test failure:', err);
  process.exit(1);
});
