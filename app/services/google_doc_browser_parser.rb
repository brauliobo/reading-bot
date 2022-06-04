class GoogleDocBrowserParser < BaseParser

  OPTS = {
    headless: true,
    devtools: true,
    executable_path: ENV['PUPPETEER_EXECUTABLE_PATH'],
  }

  class_attribute :browser
  def self.load
    Thread.new do
      Puppeteer.launch(**OPTS) do |browser|
        self.browser = browser
        sleep 1.year # keep browser open
      end
    end
    sleep 2 # wait for browser to load
  end

  attr_reader :page, :parsed, :sections

  def initialize resource, opts = SymMash.new
    super
    self.class.load unless browser

    load_page
    reload
  end

  def updated_content
    @sections.each.with_object [] do |sec, a|
      paras = parse_sec sec
      next if paras.blank?
      paras = paras.split("\n").map(&:strip).select(&:presence)
      paras.each do |p|
        next if p.blank?
        a << SymMash.new(
          final: [p],
        )
      end
    end
  end

  protected

  def load_page
    @page = browser.new_page.tap do |p|
      p.default_navigation_timeout = 60_000
      p.goto resource, wait_until: 'domcontentloaded'
    end
  end

  def reload
    @parsed   = Nokogiri::HTML page.content
    @sections = @parsed.css('script:contains("DOCS_modelChunkLoadStart")')
  end

  def parse_sec sec
    sec = sec.text.match(/= (.*); DOCS_modelChunkLoadStart/)&.captures&.first
    return unless sec
    sec = JSON.parse sec
    sec = Hashie::Mash.new sec.first
    sec.s
  end

end
