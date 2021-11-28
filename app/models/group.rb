class Group < ApplicationRecord

  attr_accessor :page

  def parsed_page
    @parsed_page ||= GoogleDocParser.new page
  end

end
