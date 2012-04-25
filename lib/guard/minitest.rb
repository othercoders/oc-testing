require 'guard'
require 'guard/guard'
require 'guard/helpers'

module Guard
  class MiniTest < Guard
    def initialize(watchers = [], options = {})
      super
      watchers << Watcher.new(%r{^test/.+_test\.rb$}) if watchers.empty?

      @options[:rails] ||= File.exists?('config/application.rb')
      if options[:rails]
        watchers << Watcher.new(%r|app/controllers/(.*)\.rb|, proc { |m| "test/functional/#{m[1]}_test.rb" })
        watchers << Watcher.new(%r|app/models/(.*)\.rb|, proc { |m| "test/unit/#{m[1]}_test.rb" })
      end
    end

    def start
    end

    def stop
    end

    def reload
    end

    def run_all
      run_on_change Dir['test/**/*_test.rb']
    end

    def run_on_change(paths)
      paths = paths.select { |path| File.exists?(path) }
      unless paths.empty?
        info "running #{paths.join(', ')}", reset: true
        run('testdrb', '-Itest', *paths, stdout: results = StringIO.new)
        notify results.string.split($/) unless @options[:notify] == false
      end
    end

    def notify(messages)
      return if messages.empty? || messages.nil?

      message = messages[-5..-1].reverse.detect { |line| line =~ /assertions/ }

      message.gsub!(/\[\d+m/, '') if message
      image, message = case message
                       when /(\d+) tests.*?(\d+) assertions.*?0 failures.*?0 errors.*?0 skips/
                         [:success, "#$1 Passing test#{'s' if $1.to_i > 1} with #$2 assertion#{'s' if $2.to_i > 1}"]
                       when /0 failures.*?0 errors.*?(\d+) skips/ then [:pending, "#$1 Pending tests"]
                       when /(\d+) failures.*?(\d+) errors.*?(\d+) skips/
                         [:failed, "#$1 Failure#{'s' if $1.to_i > 1}, #$2 Error#{'s' if $2.to_i > 1}, #$3 Pending"]
                       else [:failed, 'Failed to run command']
                       end

      Notifier.notify message, title: 'Test Results', image: image
      # system 'growlnotify', '-n', 'Watchr', '--image', "#{image}.png", '-m', message, 'Test Results' rescue nil
    end
  end
end
