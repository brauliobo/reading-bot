class BaseParser

  NEXT_LIMIT = 10

  attr_reader :resource, :opts

  def initialize resource, opts = SymMash.new
    @resource = resource
    @opts     = opts
  end

  def next_text last_text
  end

  def select paras
    Selector.new(opts).select paras
  end

end
