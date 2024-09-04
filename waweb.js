const env = require('dotenv').config().parsed;
const { Client, LocalAuth } = require('whatsapp-web.js');
const qrcode = require('qrcode-terminal'); // Import the QR code package
const fs = require('fs');

const express = require('express');
const bodyParser = require('body-parser');

const SOCK_FILE = 'run/whatsapp.sock';

async function load() {
  const app = express();
  app.use(bodyParser.urlencoded({ extended: false }));

  // HTTP API endpoint for evaluating JavaScript
  app.post('/eval', async (req, res) => {
    const input = req.body.input;
    console.log(`Running ${input}...`);
    try {
      const ret = await eval(`(async () => { return ${input}; })()`);
      res.send(ret);
    } catch (e) {
      res.send(e.message);
    }
    return res.end();
  });

  app.listen(env.WHATSAPP_API_PORT || 2002, () => {});

  // Create client with persistent session using LocalAuth
  const client = new Client({
    authStrategy: new LocalAuth(), // Stores session data
    puppeteer: {
      headless: true,
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
    console.log('Client is ready!');
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

