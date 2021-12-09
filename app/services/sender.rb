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
    last_text   = last_text.last 100 # ending of the text

    group.parsed.next_text last_text
  end

  def send chat_id, last_text
    group = self.class.load_group chat_id
    nt    = next_text group, last_text
    return puts "Can't find next! #{nt.inspect}" if nt.blank? or nt.final.blank?

    nt = nt.flat_map do |order, paras|
      fnt = format paras
      puts "Next #{order} text to post:\n#{fnt}"
      fnt
    end

    return unless confirm_yn "#{group.name}: confirm post?"
    nt.each do |fnt|
      Whatsapp.send_message group.chat_id, fnt
      sleep 1
    end
    group.update last_text: paras.join("\n")
  end

  def format paras
    Formatter.new.md paras
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

