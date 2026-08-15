class SenderService

  class_attribute :running
  self.running = false

  def self.start
    return false if running

    self.running = true
    true
  end

  def initialize
    self.class.start
  end

  def send_paras chat_id, text
    raise 'not implemented'
  end

end
