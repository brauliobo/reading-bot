class Selector

  HEADING_LIMIT = 80
  CHARS_LIMIT   = 600

  attr_reader :opts

  def initialize opts
    @opts = opts
  end

  def self.disable_heading? paras
    paras.count{ |p| p.size < HEADING_LIMIT } >= 4
  end

  def select blocks
    hi   = -1
    nt   = []
    pi   = 0
    size = 0

    blocks.each do |paras|
      paras.select.with_index do |p, i|
        np = paras[i+1]

        is_head       = p.size < HEADING_LIMIT
        is_numbered   = p =~ /^\d/
        is_footer     = is_head && is_numbered
        n_is_head     = np && np.size < HEADING_LIMIT
        n_is_numbered = np =~ /^\d/
        oversize      = nt.join.size + p.size > CHARS_LIMIT 
        middle_head   = is_head && !is_footer

        break if oversize
        break if middle_head # stop if there is a heading in the middle

        hi = i if is_head
        true
      end
      pi   += 1
      size += 1
    end

    size = 1 and nt = blocks.first if nt.blank?
    
    SymMash.new(
      blocks: size,
      text:   nt,
    )
  end

end
