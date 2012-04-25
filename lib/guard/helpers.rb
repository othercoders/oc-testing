module Guard
  class Guard
    def info(msg, options = {})
      ui :info, msg, options
    end

    def error(msg, options = {})
      ui :error, msg, options
    end

    def debug(msg, options = {})
      ui :debug, msg, options
    end

    def ui(method, msg, options)
      UI.clear if options.delete(:clear)
      UI.__send__(method, "#{self.class.name} #{msg}", options)
    end

    def timeout(time = @options[:wait], &block)
      timeout = 0

      begin
        start = Time.now
        sleep(0.1)
        timeout += Time.now - start
      end while block.call && timeout < time

      timeout >= time
    end

    def run(*cmd)
      options = cmd.last.is_a?(Hash) ? cmd.pop : {}

      stdin, stdout, stderr, wait_thr = Open3.popen3(*cmd)
      stdin.close

      stdout = thread_stream(:info, stdout, options[:stdout])
      stderr = thread_stream(:error, stderr, options[:stderr])

      stdout.join
      stderr.join

      wait_thr.value && wait_thr.value.success?
    rescue Exception => e
      false
    end

    def thread_stream(type, stream, buffer = nil)
      Thread.start do
        until stream.eof?
          line = stream.readline
          buffer.write line if buffer
          __send__ type, line.rstrip
        end
      end
    end
  end
end
