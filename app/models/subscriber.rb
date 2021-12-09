class Subscriber < Sequel::Model

  attr_accessor :parsed

  def parse
    @parsed ||= self.parser.constantize.new resource, opts
  end

  def opts
    SymMash.new self[:opts]
  end

end
