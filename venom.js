const env     = require('dotenv').config().parsed
const venom   = require('venom-bot')
const fs      = require('fs')

const express    = require('express')
const bodyParser = require('body-parser')

const SOCK_FILE = 'run/venom.sock'

async function load() {
  const app = express()
  app.use(bodyParser.urlencoded({ extended: false }))

  app.post('/eval', async (req, res) => {
    input = req.body.input
    console.log(`Running ${input}...`)
    try {
      ret = await eval(`(async () => { return ${input}; })()`)
      return res.send(ret)
    } catch(e) {
      return res.send(e.message)
    }
    console.log(ret)
  })

  app.listen(env.VENOM_API_PORT || 2002, () => {})

  const client = await venom.create({
    session:      'default',
    refreshQR:    60000,
    autoClose:    60 * 60 * 24 * 365, //never
    disableSpins: true,
    multidevice:  true,
    executablePath: env.PUPPETEER_EXECUTABLE_PATH,
  })
}

(async () => {
  await load()
})()

process.on('SIGINT', () => fs.unlinkSync(SOCK_FILE))
