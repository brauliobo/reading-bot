const venom = require('venom-bot')
var client  = null

async function load() {
  client = await venom.create(
    'default',
    null, null,
    {
      refreshQR: 15000,
      autoClose: 60 * 60 * 24 * 365, //never
      disableSpins: true
    }
  )
}

(async () => {
  await load()
})()

