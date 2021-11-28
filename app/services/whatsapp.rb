class Whatsapp

  VENOM_API_URL = "http://localhost:2002"

  extend ActionView::Helpers::JavaScriptHelper

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
