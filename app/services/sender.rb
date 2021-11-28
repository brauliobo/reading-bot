class Sender

  class_attribute :groups
  self.groups = {}

  class_attribute :browser

  OPTS = {
    headless: true,
    devtools: true,
    executable_path: ENV['PUPPETEER_EXECUTABLE_PATH'],
  }

  def self.load
    Thread.new do
      Puppeteer.launch(**OPTS) do |browser|
        self.browser = browser
        sleep 1.year # keep browser open
      end
    end
    sleep 2 # wait for browser to load
  end

  def self.load_group chat_id
    group = groups[chat_id] ||= Group.where(chat_id: chat_id).first
    page  = browser.new_page
    page.goto group.doc_url, wait_until: 'domcontentloaded'
    group.page = page
    group
  end

  def next_text group, last_text
    group.parsed_page.next_text last_text
  end

  def send chat_id, last_text
    group = self.class.load_group chat_id
    nt    = next_text group, last_text
    puts nt
  end

  def send_all last_text
    pages.each do |g, p|
      send g.chat_id, last_text
    end
  end

end

