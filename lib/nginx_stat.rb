require "English"

unless $LOAD_PATH.include?(File.expand_path(File.dirname(__FILE__)))
  $LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))
end

require 'thread'
require 'curses'
require "nginx_stat/io_tail"

##
# NginxStat displays the current requests per second and average request time.
# Default interval is 10 seconds.

class NginxStat

  ##
  #   NginxStat.start 'online-43things.log', 'online-43people.log', 10
  #
  # Starts a new NginxStat for +filenames+ that prints every +interval+
  # seconds.
  #
  # Stats for multiple log files requires curses.

  def self.start(*args)
    interval = 10
    interval = Float(args.pop) if Float(args.last) rescue nil

    stats = []

    if args.length > 1 and not defined? Curses then
      $stderr.puts "Multiple logfile support requires curses"
      exit 1
    end

    if defined? Curses then
      Curses.init_screen
      Curses.clear
      Curses.addstr "Collecting data...\n"
      Curses.refresh
    end

    args.each_with_index do |filename, offset|
      stat = self.new File.open(filename), interval, offset
      stat.start
      stats << stat
    end

    stats.each { |stat| stat.thread.join }
  end

  ##
  # The log reading thread

  attr_reader :thread

  ##
  # Current status line

  attr_reader :status

  ##
  # Creates a new NginxStat that will listen on +io+ and print every
  # +interval+ seconds.  +offset+ is only used for multi-file support.

  def initialize(io, interval, offset = 0)
    @io = io
    @io_path = File.basename io.path rescue 'unknown'
    @interval = interval.to_f
    @offset = offset

    @mutex = Mutex.new
    @status = ''
    @last_len = 0
    @count = 0
    @time = 0.0
    @thread = nil
  end

  ##
  # Starts the NginxStat running.  This method never returns.

  def start
    trap 'INT' do
      Curses.close_screen if defined? Curses
      exit
    end
    start_printer
    read_log
  end

  def print
    if defined? Curses then
      Curses.setpos @offset, 0
      Curses.addstr ' ' * @last_len
      Curses.setpos @offset, 0
      Curses.addstr "#{@io_path}\t#{@status}"
      Curses.refresh
    else
      print "\r"
      print ' ' * @last_len
      print "\r"
      print @status
      $stdout.flush
    end
  end

  private

  ##
  # Starts a thread that prints log information every +interval+ seconds.

  def start_printer
    Thread.start do
      count_sec = 0
      average_time = 0.0
      
      loop do
        sleep @interval

        @mutex.synchronize do
          count_sec = @count / @interval
          average_time = @time / @count.to_f
          @count = 0
          @time = 0.0
        end

        @status = "%5.1f req/sec, %.2f sec per req" % [count_sec, average_time]

        print

        @last_len = status.length
      end
    end
  end

  ##
  # Starts a thread that reads from +io+, updating NginxStat counters as it
  # goes.

  def read_log
    @thread = Thread.start do
      @io.tail_lines do |line|
        unless exclude?(line)
          @mutex.synchronize { @time += line.strip.split.last.to_f }
          @mutex.synchronize { @count += 1 }
        end
      end
    end
  end
  
  def exclude?(line)
    line =~ /\.(gif|jpg|jpeg|png|ico)/
  end

end

