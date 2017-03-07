# A class used as a destination for periodically writing out batch-written
# JSON formattable payloads. Can be used for stats logs, SQL replay logs and the like.
# Is thread safe and uses gzip compression. Writes are performed using a binary UNIX
# append, which with a small-ish record size should guarantee atomic append.
class Fourtrack::Recorder
  require 'logger'
  NULL_LOGGER = Logger.new(nil)
  def initialize(output_path:, flush_after_n:, logger: NULL_LOGGER)
    @output_path = File.expand_path(output_path)
    @pid_at_create = Process.pid
    @logger = logger
    @buf = []
    @mux = Mutex.new
    @flush_every = flush_after_n
    # Attempt to open the file for writing,
    # which will raise an exception outright if we do not have access
    File.open(@output_path, 'a') {}
    # and once we know we were able to open it, install an at_exit block for ourselves
    install_at_exit_hook!
  end
  
  def pending?
    len = @mux.synchronize { @buf.length }
    len.nonzero?
  end
  
  def <<(payload)
    # Get the current PID.
    mypid = Process.pid
    len_so_far  = @mux.synchronize {
      # If the current PID doesn't match the one
      # that was set at instantiation, it means the process was
      # forked and we now possible also hold records for the parent
      # process, which we have to discard (it is the responsibility
      # of the parent to flush it's records, not ours!).
      if mypid != @pid_at_create
        @pid_at_create = mypid
        @buf.clear
      end
      @buf << payload
      @buf.length
    }
    flush! if len_so_far > @flush_every
    self
  end
  
  def flush!
    # Refuse to flush and empty the buffer if flush! is called
    # within a child and the object still has records pending
    mypid = Process.pid
    if mypid != @pid_at_create
      @logger.debug { "%s: Flush requested child PID %d, will inhibit flush and empty the record log first" % mypid }
      # Do not flush since we are in the child now
      @mux.synchronize { @buf.clear }
      return
    end

    io_buf = StringIO.new

    @mux.synchronize do
      @logger.debug { "%s: Compressing %d records from PID %d" % [self, @buf.length, Process.pid] }
      z = Zlib::GzipWriter.new(io_buf)
      @buf.each {|record| z.puts(JSON.dump(record) + "\n") }
      z.finish
      @buf.clear
    end

    @logger.debug { "%s: Flushing to %s, size before flush %d" % [self, @output_path, File.size(@output_path)] }
    File.open(@output_path, 'ab') { |f| f << io_buf.string }
    @logger.debug { "%s: After flush to %s size %d" % [self, @output_path, File.size(@output_path)] }

    io_buf.truncate(0)
  end

  private

  def install_at_exit_hook!
    at_exit { flush! if pending? }
  end
end
