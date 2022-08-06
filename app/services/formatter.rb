class Formatter

  LINE_SEP = "\n\n"

  def self.md_format nt
    i = Formatter.new
    nt.each.with_object [] do |(order, paras), l|
      next unless paras
      l << i.md(paras)
    end
  end

  def md paras
    paras = paras.flat_map{ |p| p.split "\n" }
    disable_heading = Selector.disable_heading? paras

    paras.map do |p|
      p = p.dup

      if !disable_heading and p.size < Selector::HEADING_LIMIT
        p = "*#{p}*"
      elsif (ih = p.index ':') and ih < Selector::HEADING_LIMIT
        p.insert 0, '*'
        p.insert ih+1, '*'
      end

      "_#{p}_"
    end.join LINE_SEP
  end

end
