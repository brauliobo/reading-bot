class Formatter

  LINE_SEP = "\n\n"

  def md paras
    paras.map do |p|
      p.strip!
      p = "_#{p}_"
      p = "*#{p}*" if p.size < Selector::HEADING_LIMIT
      p
    end.join LINE_SEP
  end

end
