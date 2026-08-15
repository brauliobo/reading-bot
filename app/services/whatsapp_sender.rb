class WhatsappSender < SenderService

  WAWEB_API_PORT = (ENV['WA_API_PORT'] || ENV['WHATSAPP_API_PORT'] || 2002).to_i
  WAWEB_API_URL  = "http://localhost:#{WAWEB_API_PORT}"

  HEADERS = {'Content-type' => 'application/x-www-form-urlencoded'}

  def self.start
    return unless super

    return if port_open? WAWEB_API_PORT
    waweb_start
  end

  def send_paras chat_id, paras
    text = Formatter.md_format paras
    response = self.class.send_message chat_id, text

    SymMash.new(
      id:      response.dig('id', '_serialized') || response['id'],
      text:    text,
      sent_at: Time.now,
    )
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
    run "client.sendMessage(#{JSON.generate chat_id}, #{JSON.generate text})"
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

  def self.port_open? port
    system "lsof -i:#{port}", out: '/dev/null'
  end

end
