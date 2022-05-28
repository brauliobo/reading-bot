class Scheduler

  class_attribute :rufus
  self.rufus = Rufus::Scheduler.new

  def self.run
    Sender.load_all
    Sender.subscribers.each do |chat_id, sub|
      next if sub.schedule_cron.blank?

      puts "#{sub.name}: scheduling #{sub.schedule_cron}"
      rufus.cron sub.schedule_cron do
        Sender.new.send chat_id, noconfirm: true
      end
    end
  end

  def self.reload
    rufus.shutdown :wait
    self.rufus = Rufus::Scheduler.new
    run
  end

  def self.restart
    Rails.application.reloader.reload!
    reload
  end

end
