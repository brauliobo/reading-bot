class Formatter

  LINE_SEP = "\n\n"

  def md paras
    paras.map do |p|
      p.strip!
      p = "_#{p}_"

      if p.size < Selector::HEADING_LIMIT
        p = "*#{p}*"
      elsif (ih = p.index ':') and ih < Selector::HEADING_LIMIT
        p.insert 0, '*'
        p.insert ih+1, '*'
      end

      p
    end.join LINE_SEP
  end

end
