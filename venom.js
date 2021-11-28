const env     = require('dotenv').config().parsed
const venom   = require('venom-bot')
const express = require('express')
const fs      = require('fs')

const SOCK_FILE = 'run/venom.sock'

async function load() {
  const client = await venom.create(
    'default',
    null, null,
    {
      refreshQR: 15000,
      autoClose: 60 * 60 * 24 * 365, //never
      disableSpins: true
    }
  )
  const app = express()

  app.get('/eval', async (req, res) => {
    input = req.body?.text ? req.body.text : req.query.input
    console.log(`Running ${input}...`)
    try {
      ret = await eval(`(async () => { return ${input}; })()`)
      return res.send(ret)
    } catch(e) {
      return res.send(e.message)
    }
    console.log(ret)

  })

  app.listen(env.VENOM_API_PORT, () => {})
}

(async () => {
  await load()
})()

process.on('SIGINT', () => fs.unlinkSync(SOCK_FILE))
