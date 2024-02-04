class SenderService

  class_attribute :running
  self.running = false

  def self.start
    return unless running
    self.running = true
  end

  def initialize
    self.class.start
  end

  def send_paras chat_id, text
    raise 'not implemented'
  end

end
