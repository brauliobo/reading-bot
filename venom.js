const venom   = require('venom-bot')
const express = require('express')

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
  app.listen('/tmp/sock', () => {
  })
}

(async () => {
  await load()
})()

