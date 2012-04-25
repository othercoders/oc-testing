require 'guard'
require 'guard/guard'
require 'guard/helpers'

module Guard
  class Spork < Guard
    @@children = []
    def initialize(watchers = [], options = {})
      super

      @options ||= {}
      @options[:bundler] ||= File.exists?('Gemfile')
      @options[:rails] ||= File.exists?('config/application.rb')
      @options[:minitest] ||= File.exists?('test/test_helper.rb') && 8988
      @options[:wait] ||= 20

      if @options[:rails]
        watchers << Watcher.new('config/routes.rb')
        watchers << Watcher.new('config/environments/test.rb')
        watchers << Watcher.new(%r{config/initializers/.+\.rb})
        watchers << Watcher.new(%r{config/(?:environment|application|boot)\.rb})
        if @options[:minitest]
          watchers << Watcher.new(%r{test/support/.*\.rb})
        end
      end

      if @options[:minitest]
        watchers << Watcher.new('test/test_helper.rb')
      end

      if @options[:bundler]
        watchers << Watcher.new('Gemfile.lock')
      end

      Signal.trap('CHLD', method(:reap_children))
    end

    def start
      info "starting Spork"
      launch
      verify
    end

    def stop
      info 'stopping Spork'
      kill
    end

    def reload
      stop
      start
    end

    def run_on_change(paths)
      reload
    end

    def launch
      unless pid = fork
        Signal.trap('QUIT', 'IGNORE')
        Signal.trap('INT', 'IGNORE')
        Signal.trap('TSTP', 'IGNORE')

        ::Bundler.with_clean_env do
          # Open3.popen3('rvm', ruby, 'ruby', '-e', 'eval($stdin.read)') do |stdin, stdout, stderr|
          #   stdin.write <<-RUBY
          #     begin
          #       old_verbose, $VERBOSE = $VERBOSE, nil
          #       ARGV = #{ARGV.inspect}
          #     ensure
          #       $VERBOSE = old_verbose
          #     end
          #     require 'bundler/setup'
          #     load Gem.bin_path('sport-testunit', 'testdrb')
          #   RUBY
          #   stdin.close
          #   stdout = thread_stream($stdout, stdout)
          #   stderr = thread_stream($stderr, stderr)

          #   stdout.join
          #   stderr.join
          # end
          # exec('script/spork', 'MiniTest')
          exec 'spork'
        end
      end

      debug "spawned spork #{pid}"
      @@children << pid
    end

    def verify
      if timeout { TCPSocket.new('localhost', @options[:minitest]).close rescue false }
        error 'unable to verify new spork'
        Notifier.notify 'Spork failed to (re)start', title: 'Spork', image: :failed
      else
        info 'started'
        Notifier.notify 'Spork successfully started', title: 'Spork', image: :success
      end
    end

    def kill
      debug "killing sporks #{@@children.join(', ')}"
      @@children.each { |child| Process.kill 'TERM', child }
    end

    def reap_children(sig)
      loop do
        begin
          pid, stat = Process.wait2(-1, Process::WNOHANG)
          break if pid.nil?
          debug "Reaping spork #{pid}" if @@children.delete(pid)
        rescue Errno::ECHILD
          break
        end
      end
    end
  end
end
