class Subscriber < Sequel::Model

  NEXT_LIMIT = 10

  attr_accessor :parsed

  def parse
    @parsed ||= self.parser.constantize.new self, opts
  end

  def content
    update_content unless self[:content]
    self[:content].map{ |o| SymMash.new o }
  end

  def update_content
    update content: parse.updated_content
  end

  def last_sent
    SymMash.new self[:last_sent]
  end
  def opts
    SymMash.new self[:opts]
  end

  def next_text last_text
    reload # important and senders outside the daemon might have been triggered
    last_paras = if last_text then [last_text] else self.last_paras end
    parse.next_text last_paras
  end

  def lookup last_paras
    content.each_cons(NEXT_LIMIT).with_index do |(pr, r, *nexts), i|
      sized_last = if last_paras.size == 1 then last_paras *= 2 else last_paras end
      found = [pr, r].zip(sized_last).find do |cr, lp|
        row_find cr, lp
      end&.first
      # look for joined content (poetry's case)
      found = r if !found and row_find r, last_paras
      next unless found
      nexts.prepend(r) and r = pr if found == pr and last_paras.size == 1

      return SymMash.new(
        last: r.merge(
          index: i+1,
        ),
        next: {
          original: (nexts.flat_map(&:original) if nexts.first.original),
          final:    nexts.flat_map(&:final),
        }
      )
    end
    nil
  end

  ##
  # Return the index of the paragraph found in `content`
  #
  def row_find row, last_text = self.last_sent.text
    last_text = last_text.join if last_text.is_a? Array

    cells  = row.final
    cells += row.original if row.original
    cells  = cells.join if cells.is_a? Array

    return true if cells.index last_text
    false
  end

  def last_paras 
    # only last parameter could be a date (not enough)
    last_sent.text.split("\n").last(2)
  end

end
