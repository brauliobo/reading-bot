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

  def next_text last_text
    sec,nsec  = nil
    sections.each_cons 2 do |_sec, _nsec|
      next unless _sec.text.index last_text
      sec  = parse_sec _sec
      nsec = parse_sec _nsec
      break
    end
    return puts "Can't find paragraph" if sec.blank?
    paras = sec.split("\n") + nsec.split("\n")

    nt = nil
    i  = nil
    paras.reject!{ |p| p.blank? }
    paras.each.with_index do |p, _i|
      break i = _i if p.index last_text
    end

    lp = paras[i]

    SymMash.new(
      last:  lp,
      final: select(paras[(i+1)..-1]),
    )
  end

  protected

  def parse_sec sec
    sec = sec.text.match(/= (.*); DOCS_modelChunkLoadStart/).captures.first
    sec = JSON.parse sec
    sec = Hashie::Mash.new sec.first
    sec.s
  end

end
