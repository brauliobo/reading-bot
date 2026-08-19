class WhatsappSender < SenderService

  require 'timeout'

  WAWEB_API_PORT = (ENV['WA_API_PORT'] || ENV['WHATSAPP_API_PORT'] || 2002).to_i
  WAWEB_API_URL  = "http://localhost:#{WAWEB_API_PORT}"

  HEADERS = {'Content-type' => 'application/x-www-form-urlencoded'}

  def self.start
    return unless super

    waweb_start unless port_open? WAWEB_API_PORT
    Timeout.timeout(120) do
      sleep 0.5 until port_open?(WAWEB_API_PORT) && ready?
    end
  rescue
    self.running = false
    raise
  end

  def send_paras chat_id, paras
    text = Formatter.md_format paras
    id   = self.class.send_message(chat_id, text)['id']
    id   = id['_serialized'] if id.is_a? Hash
    SymMash.new id: id, text: text, sent_at: Time.now
  end

  delegate :send_message, to: :class

  protected

  def self.waweb_start
    Thread.new do
      while !@stop
        pid = spawn 'node waweb.js'
        trap(:SIGINT) { @stop = true and Process.kill :TERM, pid }

        Process.waitpid pid
        next if @stop
        puts 'waweb: restarting'
        sleep 10.seconds 
      end
    end
  end

  def self.send_message chat_id, text
    chat_id = JSON.generate chat_id
    text    = JSON.generate text
    run <<~JS
      client.pupPage.evaluate(async (chatId, text) => {
        const chat = await window.WWebJS.getChat(chatId, {getAsModel: false});
        if (!chat) throw new Error('WhatsApp chat was not found');

        await window.WWebJS.sendSeen(chatId);
        await window.WWebJS.sendMessage(chat, text, {
          linkPreview: true,
          parseVCards: true,
          mentionedJidList: [],
          ignoreQuoteErrors: true,
          waitUntilMsgSent: true,
        });
        const last = chat.msgs.getModelsArray().filter(m => m.id.fromMe).pop();
        if (!last) throw new Error('WhatsApp returned no sent message');
        return {id: String(last.id)};
      }, #{chat_id}, #{text})
    JS
  end

  def self.run code
    res = http.post "#{WAWEB_API_URL}/eval", {input: code}, HEADERS
    response = JSON.parse res.body
    raise response.fetch('error', 'WhatsApp API request failed') unless response['ok']

    response.fetch 'result'
  end

  def self.http
    Mechanize.new
  end

  def self.ready?
    JSON.parse(http.get("#{WAWEB_API_URL}/health").body).fetch 'ready'
  end

  def self.port_open? port
    system "lsof -i:#{port}", out: '/dev/null'
  end

end
