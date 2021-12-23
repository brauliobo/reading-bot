class Selector

  HEADING_LIMIT = 80
  CHARS_LIMIT   = 800

  attr_reader :opts

  def initialize opts
    @opts = opts
  end

  def self.disable_heading? paras
    paras.count{ |p| p.size < HEADING_LIMIT } >= 4
  end

  def select paras
    nt = []
    hi = -1

    paras.each.with_index do |p, i|
      break if i > hi+1 and nt.join.size + p.size > CHARS_LIMIT
      np = paras[i+1]
      # stop if there is a heading in the middle
      break if !opts.middle_headline and i > hi+1 and p.size < HEADING_LIMIT and (!np or np.size < HEADING_LIMIT)

      hi  = i if p.size < HEADING_LIMIT
      nt << p
    end

    nt.pop if !Selector.disable_heading?(paras) and nt.last.size < HEADING_LIMIT

    nt
  end

end
