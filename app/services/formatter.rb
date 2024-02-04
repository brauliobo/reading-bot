class Formatter

  LINE_SEP = "\n\n"

  def self.md_format nt, inner_escape: nil
    f = Formatter.new
    f.md nt, ie: inner_escape
  end

  def md paras, ie:
    paras = paras.flat_map{ |p| p.split "\n" }
    disable_heading = Selector.disable_heading? paras

    paras.map do |p|
      p = p.dup
      p = ie.call p if ie

      if !disable_heading and p.size < Selector::HEADING_LIMIT and p !~ /^\d/
        p = "*#{p}*"
      elsif (ih = p.index ':') and ih < Selector::HEADING_LIMIT
        p.insert 0, '*'
        p.insert ih+1, '*'
      end

      "_#{p}_"
    end.join LINE_SEP
  end

end
