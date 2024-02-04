class Formatter

  LINE_SEP = "\n\n"

  def self.md_format paras, inner_escape: nil
    Formatter.new.md paras, ie: inner_escape
  end
  def self.html_format paras, inner_escape: CGI.method(:escapeHTML)
    Formatter.new.html paras, ie: inner_escape
  end

  def html paras, **params
    format paras, tag: :html, **params
  end

  def md paras, **params
    format paras, tag: :md, **params
  end

  protected

  def format paras, tag:, ie: nil
    paras = paras.flat_map{ |p| p.split "\n" }
    disable_heading = Selector.disable_heading? paras

    paras.map do |p|
      p = p.dup
      p = ie.call p if ie

      if !disable_heading and p.size < Selector::HEADING_LIMIT and p !~ /^\d/
        p = send "#{tag}_bold", p
      elsif (ih = p.index ':') and ih < Selector::HEADING_LIMIT
        p.insert 0, '*'
        p.insert ih+1, '*'
      end

      send "#{tag}_italic", p
    end.join LINE_SEP
  end

  def md_bold text
    "*#{text}*"
  end
  def md_italic text
    "_#{text}_"
  end

  def html_bold text
    "<b>#{text}</b>"
  end
  def html_italic text
    "<i>#{text}</i>"
  end

end
