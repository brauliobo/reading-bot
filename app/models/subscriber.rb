class Subscriber < Sequel::Model

  NEXT_LIMIT = 10

  attr_reader :parsed

  def parse
    @parsed ||= parser.constantize.new self, opts
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

  def next_text last_sent = self.last_sent
    # only last parameter could be a date (not enough)
    paras = last_sent.text.split("\n").last(2) if last_sent
    return unless nt = lookup(paras)

    nt.last          = last_sent
    nt.next.final    = select nt.next.final
    nt.next.original = nt.next.original.first nt.next.final.size if nt.next.original
    nt
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

      nexth = SymMash.new
      nexth.original = nexts.flat_map(&:original) if nexts.first.original
      nexth.final    = nexts.flat_map(&:final)

      return SymMash.new(
        last: r.merge(
          index: i+1,
        ),
        next: nexth,
      )
    end
    nil
  end

  def md_format nt
    Formatter.md_format nt
  end
  def select paras
    Selector.new(opts).select paras
  end

  def test **params
    bak       = self.values.slice :last_sent, :last_sent_at
    last_sent = self.last_sent
    while prev = last_sent
      nt = next_text last_sent
      last_sent = next_update nt

      binding.pry unless last_sent and last_sent.index
      puts "LAST: #{last_sent.merge(text: last_sent.text.first(50)).inspect}"

      binding.pry if prev and prev.index > last_sent.index
    end
  ensure
    puts "Restoring: #{bak.inspect}"
    update bak
  end

  def next_update nt
    last_sent = SymMash.new index: nt.last.index + nt.next.final.size, text: nt.next.values.join("\n")
    last_sent.tap{ update last_sent: last_sent, last_sent_at: Time.now }
  end

protected

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

end
