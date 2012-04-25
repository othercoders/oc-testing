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
      paths = paths.select { |path| File.exists?(path) }.uniq
      unless paths.empty?
        info "running #{paths.join(', ')}", clear: true
        system 'testdrb', '-Itest', *paths
      end
    end
  end
end
