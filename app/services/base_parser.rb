class BaseParser

  attr_reader :resource

  def initialize resource
    @resource = resource
  end

  def next_text last_text
  end

  def select paras
    Selector.new.select paras
  end

  def report_last lp
    puts "Found last paragraph: \n#{lp}\n\n--------------"
  end

end
