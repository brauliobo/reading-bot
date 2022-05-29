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
    return unless nt = lookup(last_paras)

    nt.next.final    = select nt.next.final
    nt.next.original = nt.next.original.first nt.next.final.size if nt.next.original
    nt
  end

  def select paras
    Selector.new(opts).select paras
  end

end
