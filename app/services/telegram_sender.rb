class TelegramSender < SenderService

  extend  TelegramHelpers
  include TelegramHelpers

  class_attribute :bot

  def self.start
    super
    connect
    sleep 0.5 while !bot
  end

  def send_paras chat_id, paras
    chat_id, reply_id = chat_id.split '@' if chat_id.index '@'
    smsg = SymMash.new chat: {id: chat_id}, message_id: reply_id
    text = Formatter.html_format paras
    puts text if ENV['DEBUG']
    msg  = send_message smsg, text, message_thread_id: reply_id, parse_mode: 'HTML'
    SymMash.new(
      id:      msg.result.message_id,
      text:    msg.text,
      sent_at: Time.at(msg.result.date),
    )
  end

  protected

  def self.connect
    Thread.new do
      wait_net_up
      Telegram::Bot::Client.run ENV['TELEGRAM_BOT_TOKEN'], logger: Logger.new(STDOUT) do |bot|
        self.bot = bot

        puts 'bot: started, listening'
        bot.listen do |msg|
          Thread.new do
            next unless msg.is_a? Telegram::Bot::Types::Message
            #react msg
          end
          Thread.new{ sleep 1 and abort } if @exit # wait for other msg processing and trigger systemd restart
        end
      end
    end
  end

end

