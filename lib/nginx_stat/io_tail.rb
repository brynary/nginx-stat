##
# IOTail provides a tail_lines method as a mixin.  By default it is included
# into IO and StringIO, if present.  If you require StringIO after IOTail,
# then simply open StringIO and include IOTail.

module IOTail

  ##
  # Jumps to near the end of the IO, then yields each line, waiting for new
  # lines if it reaches eof?

  def tail_lines(&block) # :yields: line
    self.seek(-1, IO::SEEK_END)
    self.gets

    loop do
      self.each_line(&block)

      if self.eof? then
        sleep 0.25
        self.pos = self.pos # reset eof?
      end
    end
  end

end

class IO # :nodoc:
  include IOTail
end

if defined? StringIO then
  class StringIO # :nodoc:
    include IOTail
  end
end

