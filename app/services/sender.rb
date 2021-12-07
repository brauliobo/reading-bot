class Sender

  class_attribute :groups
  self.groups = {}

  def self.load_group chat_id
    groups[chat_id] ||= Group.where(chat_id: chat_id).first.tap do |g|
      g.parse
    end
  end

  def initialize
  end

  def next_text group, last_text
    last_text ||= group.last_text
    group.parsed.next_text last_text
  end

  def send chat_id, last_text
    group = self.class.load_group chat_id
    nt    = next_text group, last_text
    return if nt.blank?

    fnt = Formatter.new.md nt
    nt  = nt.join "\n"

    puts "Next text to post:\n#{fnt}"
    if confirm_yn "#{group.name}: confirm post?"
      Whatsapp.send_message group.chat_id, fnt
      group.update last_text: nt
    end
  end

  def send_all last_text
    pages.each do |g, p|
      send g.chat_id, last_text
    end
  end

  def confirm_yn question
    puts "\n#{question} (yN)"
    return true if STDIN.gets.chomp == 'y'
  end

end

