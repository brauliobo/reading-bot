class Selector

  HEADING_LIMIT = 50
  CHARS_LIMIT   = 800

  def select paras
    nt = []

    for i in 0..4 do
      break unless p = paras[i]
      break if nt.join.size + p.size > CHARS_LIMIT
      np = paras[i+1]
      # stop if there is a heading in the middle
      break if p.size < HEADING_LIMIT and (!np or np.size > HEADING_LIMIT)
      nt << p
    end

    nt
  end

end
