class Group < Sequel::Model

  attr_accessor :parsed

  def parse
    @parsed ||= self.parser.constantize.new resource
  end

end
