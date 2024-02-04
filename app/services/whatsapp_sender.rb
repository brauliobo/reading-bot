class WhatsappSender < SenderService

  VENOM_API_PORT = ENV['VENOM_API_PORT']&.to_i || 2002
  VENOM_API_URL  = "http://localhost:#{VENOM_API_PORT}"

  HEADERS = {'Content-type' => 'application/x-www-form-urlencoded'}

  extend ActionView::Helpers::JavaScriptHelper

  def self.start
    super
    venom_start
  end

  def send_paras chat_id, paras
    text = Formatter.md_format paras
    self.class.send_message msg, text, message_thread_id: reply_id
    nil # FIXME
  end

  delegate :send_message, to: :class

  protected

  def self.venom_start
    Thread.new do
      while !@stop
        pid = spawn 'node venom.js'
        trap(:SIGINT) { @stop = true and Process.kill :KILL, pid }

        Process.waitpid pid
        next if @stop
        puts 'venom: restarting'
        sleep 10.seconds 
      end
    end
  end

  def self.send_message chat_id, text
    run "client.sendText('#{chat_id}', '#{escape_javascript text}')"
  end

  def self.run code
    res = http.post "#{VENOM_API_URL}/eval", {input: code}, HEADERS
    JSON.parse res.body
  end

  def self.http
    Mechanize.new
  end

end
