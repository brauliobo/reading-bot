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
    hi = -1
    nt = []
    nc = 0 # chars count

    fparas = blocks.flat_map.with_index do |b,i|
      b.map{ |p| SymMash.new i: i, p: p }
    end
    bis = Set.new
    fparas.each.with_index do |b, i|
      p,bi   = b.p, b.i
      nb     = fparas[i+1]
      np,nbi = nb&.p, nb&.i

      is_head       = p.size < HEADING_LIMIT
      is_numbered   = p =~ /^\d/
      is_footer     = is_head && is_numbered
      n_is_head     = np && np.size < HEADING_LIMIT
      n_is_numbered = np =~ /^\d/
      n_is_footer   = n_is_head && n_is_numbered
      oversize      = i > hi+1 && nc + p.size > CHARS_LIMIT 
      middle_head   = i > hi+1 && is_head && !is_footer

      break if oversize
      break if middle_head # stop if there is a heading in the middle

      hi = i if is_head
      nc += p.size
      nc += np.size  if n_is_footer
      break bis.merge [bi,nbi] if n_is_footer
      break bis << bi if is_footer
      bis << bi
    end
    size = bis.size
    nt   = bis.flat_map{ |bi| blocks[bi] }

    size = 1 and nt = blocks.first if nt.blank?
    
    SymMash.new(
      blocks: size,
      text:   nt,
    )
  end

end
