class Scheduler

  def self.run
    scheduler = Rufus::Scheduler.new

    Sender.load_all
    Sender.subscribers.each do |chat_id, sub|
      next if sub.schedule_cron.blank?

      puts "#{sub.name}: scheduling #{sub.schedule_cron}"
      scheduler.cron sub.schedule_cron do
        Sender.new.send chat_id, noconfirm: true
      end
    end

    sleep 365.days while true
  end

end
