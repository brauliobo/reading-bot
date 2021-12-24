class Formatter

  LINE_SEP = "\n\n"

  def md paras
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
