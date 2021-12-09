class Sender

  class_attribute :subscribers
  self.subscribers = {}

  def self.load_subscriber chat_id
    subscribers[chat_id] ||= Subscriber.where(chat_id: chat_id).first.tap do |g|
      g.parse
    end
  end

  def initialize
  end

  def next_text subscriber, last_text
    last_text ||= subscriber.last_text
    last_text   = last_text.last 100 # ending of the text

    subscriber.parsed.next_text last_text
  end

  def send chat_id, last_text
    subscriber = self.class.load_subscriber chat_id
    nt    = next_text subscriber, last_text
    return puts "Can't find next! #{nt.inspect}" if nt.blank? or nt.final.blank?

    fnt = nt.flat_map do |order, paras|
      fp = format paras
      puts "Next #{order} text to post:\n#{fp}"
      fp
    end

    return unless confirm_yn "#{subscriber.name}: confirm post?"
    nt.each do |fnt|
      Whatsapp.send_message subscriber.chat_id, fnt
      sleep 1
    end
    subscriber.update last_text: nt.join("\n")
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

