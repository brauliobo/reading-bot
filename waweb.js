const env = require('dotenv').config().parsed || {};
const { Client, LocalAuth } = require('whatsapp-web.js');
const qrcode = require('qrcode-terminal'); // Import the QR code package
const fs = require('fs');

const express = require('express');
const bodyParser = require('body-parser');

const SOCK_FILE = 'run/whatsapp.sock';

async function load() {
  const app = express();
  let ready = false;
  app.use(bodyParser.urlencoded({ extended: false }));

  app.get('/health', (_req, res) => {
    res.json({ ready });
  });

  // HTTP API endpoint for evaluating JavaScript
  app.post('/eval', async (req, res) => {
    if (!ready) {
      return res.status(503).json({ ok: false, error: 'WhatsApp client is not ready' });
    }

    const input = req.body.input;
    console.log(`Running ${input}...`);
    try {
      const ret = await eval(`(async () => { return ${input}; })()`);
      res.json({ ok: true, result: ret });
    } catch (e) {
      res.status(500).json({ ok: false, error: e.message });
    }
  });

  app.listen(env.WHATSAPP_API_PORT || env.WA_API_PORT || 2002, '127.0.0.1', () => {});

  // Create client with persistent session using LocalAuth
  const client = new Client({
    authStrategy: new LocalAuth(), // Stores session data
    puppeteer: {
      headless: true,
      executablePath: env.PUPPETEER_EXECUTABLE_PATH || '/usr/bin/chromium',
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-extensions',
      ],
    },
  });

  // Display the QR code in the terminal
  client.on('qr', (qr) => {
    qrcode.generate(qr, { small: true }); // Generate the QR code in terminal
  });

  client.on('ready', () => {
    ready = true;
    console.log('Client is ready!');
  });

  client.on('disconnected', () => {
    ready = false;
  });

  client.on('message', async (msg) => {
    console.log('Received message:', msg.body);
    // You can handle incoming messages here
  });

  await client.initialize();
}

(async () => {
  await load();
})();

process.on('SIGINT', () => fs.unlinkSync(SOCK_FILE));
