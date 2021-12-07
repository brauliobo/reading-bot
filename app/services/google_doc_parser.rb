class GoogleDocParser

  attr_reader :page, :parsed, :sections

  def initialize page
    @page = page
    reload
  end

  def reload
    @parsed   = Nokogiri::HTML page.content
    @sections = @parsed.css('script:contains("DOCS_modelChunkLoadStart")')
  end

  def next_text last_text
    # ending of the text
    last_text = last_text.last 100

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
    puts "Found last paragraph: \n#{lp}\n\n--------------"

    Selector.new.select paras[(i+1)..-1]
  end

  protected

  def parse_sec sec
    sec = sec.text.match(/= (.*); DOCS_modelChunkLoadStart/).captures.first
    sec = JSON.parse sec
    sec = Hashie::Mash.new sec.first
    sec.s
  end

end
