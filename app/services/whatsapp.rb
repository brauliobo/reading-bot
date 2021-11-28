class Whatsapp

  VENOM_API_URL = "http://localhost:2002"

  def self.run code
    res = HTTPClient.new.get "#{VENOM_API_URL}/eval", input: code
    JSON.parse res.body
  end

end
