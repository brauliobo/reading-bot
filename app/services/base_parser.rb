class BaseParser

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

  def report_last lp
    puts "Found last paragraph: \n#{lp.join "\n\n"}\n\n--------------"
  end

end
