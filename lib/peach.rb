module Enumerable

  def peach threads: nil, priority: nil, impl: :threads, &block
    block   ||= -> *args {}
    threads ||= (ENV['THREADS'] || '10').to_i

    return each(&block) if threads == 1

    send "#{impl}_each", threads: threads, priority: priority, &block
  end

  def threads_each threads: nil, priority: nil, &block
    pool = Concurrent::FixedThreadPool.new threads
    # catch_each can't be used as catchblock needs to be used inside pool.post
    ret  = each do |*args|
      pool.post do
        Thread.current.priority = priority if priority
        block.call(*args)
      rescue => e
        puts "error: #{e.message}"
      end
    end

    pool.shutdown
    pool.wait_for_termination
    ret
  end

  ##
  # Don't work due to Proc#isolate
  #
  def ractors_each threads: nil, priority: nil, &block
    pipe = Ractor.new do
      loop{ Ractor.yield Ractor.receive }
    end
    workers = (1..threads).map do
      Ractor.new pipe, &block
    end

    i = 0
    each do |*args|
      i += 1
      pipe << args
    end

    (1..i).map do
      _r, ret = Ractor.select(*workers)
      ret
    end
  end

  def api_peach threads: nil, priority: nil, &block
    peach(
      threads:  threads || ENV['API_THREADS'] || 3,
      priority: priority,
      &block
    )
  end

  def cpu_peach threads: nil, priority: nil, &block
    peach(
      threads:  threads || ENV['CPU_THREADS'],
      priority: ENV['CPU_PRIORITY']&.to_i,
      &block
    )
  end

end
