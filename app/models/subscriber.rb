class Subscriber < Sequel::Model
  
  class_attribute :p_start
  self.p_start = ENV['START']&.to_i
  class_attribute :activated_start
  self.activated_start = !!p_start

  LAST_OFFSET = 5
  NEXT_LIMIT  = 10

  attr_reader :parsed

  def parse
    @parsed ||= parser.constantize.new self, opts
  end
  def update_content
    update content: parse.updated_content
  end
  def content
    update_content unless self[:content]
    self[:content].map{ |o| SymMash.new o }
  end

  def last_sent
    SymMash.new self[:last_sent]
  end
  def opts
    SymMash.new self[:opts]
  end

  def finished?
    last_sent.index + last_sent[:size] >= content.length 
  end

  def find_next last_sent = self.last_sent
    lookup_next_index last_sent
  end

  def select paras
    Selector.new(opts).select paras
  end

  def md_format nt
    Formatter.md_format nt
  end

  def test **params
    bak  = self.values.slice :last_sent, :last_sent_at
    prev = last_sent = self.last_sent
    while prev = last_sent
      break puts "FINISHED" if finished?

      nt = find_next last_sent
      last_sent = update_next nt

      raise "Missing last_sent"    if !last_sent&.index
      puts  "LAST: #{last_sent.merge(text: last_sent.text&.map{ |p| p.first(50) }.join("\n")).inspect}"
      raise "Empty text"           if last_sent.text.blank?
      raise "Same index"           if prev.index == last_sent.index
      raise "Same text"            if prev.text  == last_sent.text
      raise "Went before previous" if prev.index >  last_sent.index
      raise "Skipped text"         if prev.index +  prev[:size] < last_sent.index if !activated_start
    end
  rescue => e
    puts e.message
    binding.pry
  ensure
    puts "Restoring: #{bak.inspect}"
    update bak
  end

  def update_last last_sent
    SymMash.new(last_sent).tap{ update last_sent: last_sent, last_sent_at: Time.now }
  end
  def update_next nt
    update_last index: nt.next.index, size: nt.next.final.size, text: nt.next.final
  end

  def set_last_from_text text
    nt = lookup_next_text SymMash.new(text: text.split("\n"))
    update_last index: nt.last.index, size: 1, text: [nt.last.final.first]
  end
  def set_last_from_index index
    update_last index: index, size: 1, text: [content[index].final.first]
  end

protected

  def select_next nextc, last: self.last_sent
    original = nextc.text.flat_map(&:original) if nextc.text.first.original
    final    = nextc.text.flat_map(&:final)

    nt = SymMash.new last: last, next: {}
    nt.next.index    = nextc.index
    nt.next.final    = select final
    nt.next.original = original.first nt.next.final.size if original
    nt
  end

  def lookup_next_index last_sent = self.last_sent
    size     = (0 if p_start) || last_sent[:size] || 0
    offset   = p_start        || last_sent.index  || 0
    nstart   = offset + size
    lcontent = self.content[offset..nstart]
    ncontent = self.content[nstart..(nstart+NEXT_LIMIT)]

    raise "next_index: different text" if lcontent.first.final.first != last_sent.text.first if !p_start
    self.p_start = nil if p_start # reset after first usage

    nextc = SymMash.new index: nstart, text: ncontent
    select_next nextc, last: last_sent
  end

  def lookup_next_text last_sent = self.last_sent
    # only last parameter could be a date (not enough)
    last_paras = last_sent.text&.last(2) || content.first.final
    last_index = last_sent.index || 0

    offset     = if last_index > LAST_OFFSET then last_index - LAST_OFFSET else 0 end
    content    = self.content[offset..-1]
    next_limit = if (rem = self.content.length - last_index) > NEXT_LIMIT then NEXT_LIMIT else rem end
    content.each_cons(next_limit).with_index do |(pr, r, *nexts), i|
      sized_last = if last_paras.size == 1 then last_paras *= 2 else last_paras end
      found = [pr, r].zip(sized_last).find do |cr, lp|
        row_find cr, lp
      end&.first
      # look for joined content (poetry's case)
      found = r if !found and row_find r, last_paras
      next unless found
      nexts.prepend r if found == pr and last_paras.size == 1

      nextc = SymMash.new index: i, text: nexts
      return select_next nextc, last: found.merge(index: offset+i+1)
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
    cells  = cells.join   if cells.is_a? Array

    return true if cells.index last_text 
    false
  end

end
