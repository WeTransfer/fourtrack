class Fourtrack::Player
  def initialize(io)
    @io = io
  end

  def readlines
    [].tap {|o|  each_line{|line| o << line }}
  end

  def each_line(&blk)
    # https://github.com/exAspArk/multiple_files_gzip_reader
    # https://bugs.ruby-lang.org/issues/9790
    loop do
      break if @io.eof?
      zr = Zlib::GzipReader.new(@io)
      zr.each_line(&blk)
      unused_bytestr = zr.unused
      zr.finish
      if unused_bytestr && unused_bytestr.bytesize.nonzero?
        @io.pos -= unused_bytestr.bytesize
      else
        break
      end
    end
  end
end
