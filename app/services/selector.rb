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

  def select paras
    hi = -1
    nt = []

    paras.each.with_index do |p, i|
      np = paras[i+1]

      is_head     = p.size < HEADING_LIMIT
      is_footer   = p =~ /^\d/ && is_head
      n_is_head   = np && np.size < HEADING_LIMIT
      n_is_footer = np && np =~ /^\d/ && n_is_head
      oversize    = i > hi+1 && nt.join.size + p.size > CHARS_LIMIT 
      middle_head = i > hi+1 && is_head && !is_footer

      break if oversize
      break if middle_head # stop if there is a heading in the middle

      hi  = i if is_head
      nt << p
      nt << np and break if n_is_footer
      break if is_footer
    end

    nt << paras.first if nt.blank?

    nt
  end

end
