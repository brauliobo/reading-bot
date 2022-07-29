class BaseParser

  attr_reader :subscriber
  alias_method :sub, :subscriber
  delegate_missing_to :subscriber

  attr_reader :opts
  
  def initialize subscriber, opts = SymMash.new
    @subscriber = subscriber
    @opts       = opts
  end

  def updated_content
    raise 'updated_content: not implemented'
  end

end
