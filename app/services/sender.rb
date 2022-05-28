class Sender

  class_attribute :dry
  self.dry = !!ENV['DRY']

  class_attribute :subscribers
  self.subscribers = {}

  def self.load_subscriber chat_id
    subscribers[chat_id] ||= Subscriber.where(chat_id: chat_id).first.tap do |s|
      s.parse
    end
  end
  def self.load_all
    GoogleDocBrowserParser.load
    GoogleDocApiParser.load

    self.subscribers = {}
    Subscriber.where(enabled: true).all.peach do |s, h|
      puts "#{s.name}: loading resource"
      subscribers[s.chat_id] = s.tap{ s.parse }
    end
  end

  def initialize
  end

  def send_enabled update: false
    subscribers.each do |chat_id, sub|
      send chat_id
    end
  end

  SECTION_SEP = "\n--------------\n"

  def send chat_id, last_text: nil, update: false, noconfirm: false
    sub = self.class.load_subscriber chat_id
    sub.update_content if update
    nt  = next_text sub, last_text

    puts "\n\n"
    return puts "#{sub.name}: can't find last! #{nt.inspect}" if nt.blank? or nt.last.blank?
    puts "#{sub.name}: found last paragraph: \n#{nt.last.values_at(:original, :final).join "\n\n"}#{SECTION_SEP}"
    nt.delete :last
    return puts "#{sub.name}: can't find next! #{nt.inspect}" if nt.final.blank?

    return unless confirm sub, nt unless noconfirm
    return puts "#{sub.name}: dry run, quiting" if dry

    fnt = format sub, nt
    fnt.each do |fnp|
      Whatsapp.send_message sub.chat_id, fnp
      sleep 1
    end

    sub.update last_sent: {text: nt.values.join("\n")}, last_sent_at: Time.now
  end

  def next_text subscriber, last_text
    last_paras = if last_text then [last_text] else last_paras subscriber end

    subscriber.parsed.next_text last_paras
  end

  def confirm sub, nt
    begin
      c = command "#{sub.name}: confirm post?"
      case c.downcase
      when 'n' then return false
      when 'y' then return true
      when /o(\d)/ then nt.each{ |_,o| o.shift ($1 || 1).to_i }
      end
    end while true
  end

  def last_paras sub
    # only last parameter could be a date (not enough)
    sub.last_sent.text.split("\n").last(2)
  end

  def format sub, nt
    nt.flat_map do |order, paras|
      fp = Formatter.new.md paras
      puts "#{sub.name}: next #{order} text to post:\n#{fp}#{SECTION_SEP}"
      fp
    end
  end

  def send_all last_text
    pages.each do |s, p|
      send s.chat_id, last_text
    end
  end

  def command question
    puts "\n#{question} (yNo)"
    STDIN.gets.chomp.downcase
  end

end

