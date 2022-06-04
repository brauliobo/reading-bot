class Sender

  class_attribute :dry
  self.dry = !!ENV['DRY']

  class_attribute :interactive
  self.interactive = true

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

  def send chat_id, last_text: nil, update: false, noconfirm: !self.interactive
    sub = self.class.load_subscriber chat_id
    sub.update_content if update
    nt  = sub.next_text last_text

    return puts "#{sub.name}: can't find last! #{nt.inspect}" if nt.blank? or nt.last.final.blank?
    puts "\n\n#{sub.name}: found last paragraph: \n#{nt.last.values_at(:original, :final).join "\n\n"}#{SECTION_SEP}"
    return puts "#{sub.name}: can't find next! #{nt.next.inspect}" if nt.next.final.blank?

    fnt = format nt.next
    fnt.each{ |fp| puts "#{sub.name}: next text to post:\n#{fp}#{SECTION_SEP}" }

    return unless confirm sub, nt unless noconfirm
    return puts "#{sub.name}: dry run, quiting" if dry

    fnt.each do |fnp|
      Whatsapp.send_message sub.chat_id, fnp
      sleep 1
    end unless ENV['SKIP_SEND']
    sub.update last_sent: {index: nt.last.index + nt.next.final.size, text: nt.next.values.join("\n")}, last_sent_at: Time.now
  end

  protected

  def format nt
    nt.each.with_object [] do |(order, paras), l|
      next unless paras
      l << Formatter.new.md(paras)
    end
  end

  def confirm sub, nt
    begin
      c = command "#{sub.name}: confirm post?"
      case c.downcase
      when 'n' then return false
      when 'y' then return true
      end
    end while true
  end

  def command question
    puts "\n#{question} (yNo)"
    STDIN.gets.chomp.downcase
  end

end

