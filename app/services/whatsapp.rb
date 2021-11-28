class Whatsapp

  def self.context
    @context ||= ExecJS.compile VENOM_JS
  end

end
