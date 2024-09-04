class WhatsappSender < SenderService

  WAWEB_API_PORT = ENV['WA_API_PORT']&.to_i || 2002
  WAWEB_API_URL  = "http://localhost:#{WAWEB_API_PORT}"

  HEADERS = {'Content-type' => 'application/x-www-form-urlencoded'}

  extend ActionView::Helpers::JavaScriptHelper

  def self.start
    super
    return if port_open? WAWEB_API_PORT
    waweb_start
  end

  def send_paras chat_id, paras
    text = Formatter.md_format paras
    self.class.send_message chat_id, text
    nil # FIXME
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
    run "client.sendMessage('#{chat_id}', '#{escape_javascript text}')"
  end

  def self.run code
    res = http.post "#{WAWEB_API_URL}/eval", {input: code}, HEADERS
    JSON.parse res.body
  end

  def self.http
    Mechanize.new
  end

  def self.port_open? port
    system "lsof -i:#{port}", out: '/dev/null'
  end

end
