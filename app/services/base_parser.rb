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

  def next_text last_paras
    return unless paras = lookup(last_paras)

    final       = select paras.final
    nt          = SymMash.new last: paras.last
    nt.original = paras.original.first final.size if paras.original
    nt.final    = final
    nt
  end

  def select paras
    Selector.new(opts).select paras
  end

end
