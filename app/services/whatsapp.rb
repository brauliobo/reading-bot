class Whatsapp

  VENOM_API_URL = "http://localhost:2002"

  extend ActionView::Helpers::JavaScriptHelper

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
    res = http.post "#{VENOM_API_URL}/eval", {input: code}, {'Content-type' => 'application/x-www-form-urlencoded'}
    JSON.parse res.body
  end

  def self.http
    @http ||= HTTPClient.new
  end

end
