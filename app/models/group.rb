class Group < Sequel::Model

  attr_accessor :page

  def parsed_page
    @parsed_page ||= GoogleDocParser.new page
  end

end
