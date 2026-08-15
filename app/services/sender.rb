class Sender

  class_attribute :dry
  self.dry = !!ENV['DRY']

  class_attribute :interactive
  self.interactive = true

  class_attribute :subscribers
  self.subscribers = {}

  def self.load_subscriber chat_id
    subscribers[chat_id] ||= Subscriber.where(chat_id: chat_id).first.tap{ |s| s&.parse }
  end
  def self.load_all ds = Subscriber
    self.subscribers = {}
    ds.where(enabled: true).all.peach do |s, h|
      puts "#{s.name}: loading resource"
      subscribers[s.chat_id] = s.tap{ s.parse }
    end
  end

  def initialize
  end

  def send_enabled update: false
    subscribers.each_key do |chat_id|
      send chat_id, update: update
    end
  end

  SECTION_SEP = "\n--------------\n"

  def send chat_id, last_text: nil, update: false,
    test: false, dry: self.class.dry || !!ENV['SKIP_SEND'], noconfirm: !self.interactive

    cached = self.class.load_subscriber chat_id
    return puts "#{chat_id}: can't find subscriber" unless cached

    cached.class.db.transaction do
      sub = cached.class.where(service: cached.service, chat_id: cached.chat_id).for_update.first
      send_locked sub, last_text: last_text, update: update,
        test: test, dry: dry, noconfirm: noconfirm
    end
  end

  def test chat_id, **params
    sub = self.class.load_subscriber chat_id
    sub.test **params
  end

  def set_last_from_text chat_id, text
    sub = self.class.load_subscriber chat_id
    sub.set_last_from_text text
  end
  def set_last_from_index chat_id, index
    sub = self.class.load_subscriber chat_id
    sub.set_last_from_index index
  end

  protected

  def send_locked sub, last_text:, update:, test:, dry:, noconfirm:
    return puts "subscriber disappeared" unless sub

    puts "#{sub.name}: send"

    sub.update_content if update
    last_sent = last_text ? sub.last_from_text(last_text) : sub.last_sent
    nt = sub.find_next last_sent

    return puts "#{sub.name}: can't find last! #{nt.inspect}" if nt.blank? or nt.last.final.blank?
    puts "\n\n#{sub.name}: found last paragraph: \n#{nt.last.values_at(:original, :final).join "\n\n"}#{SECTION_SEP}"
    return puts "#{sub.name}: can't find next! #{nt.next.inspect}" if nt.next.final.blank?

    set = nt.next.slice(:original, :final).values
    set.each{ |ps| puts "#{sub.name}: next text to post:\n#{ps}#{SECTION_SEP}" }

    return puts "#{sub.name}: dry run, quiting" if dry
    return unless confirm sub, nt unless noconfirm

    return if dry or test

    msgs = set.map do |paras|
      msg = sub.sender.send_paras sub.chat_id, paras
      raise "#{sub.sender.class} returned no delivery record" unless msg
      msg.tap{ sleep 1 }
    end

    sub.update_next nt, messages: Array(sub.messages) + msgs
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
