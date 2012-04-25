class Spork::TestFramework::MiniTest < Spork::TestFramework
  DEFAULT_PORT = 8988
  HELPER_FILE = File.join(Dir.pwd, 'test/test_helper.rb')

  def run_tests(argv, stderr, stdout)
    # Redirect all test output back to spork
    ::MiniTest::Unit.output = stdout

    # MiniTest's test/unit does not support -I
    ARGV.clear
    argv.each do |item|
      case item
      when /^-I(.*)/
        if $1.empty?
          argv[i + 1].tap { argv[i + 1] = nil }
        else
          $1
        end.split(File::PATH_SEPARATOR).each do |path|
          $:.unshift path.strip
        end
      when /^-r(.*)/
        require(if $1.empty?
          argv[i + 1].tap { argv[i + 1] = nil }
        else
          $1
        end)
      when /^-e$/
        eval argv[i + 1]
        argv[i + 1] = nil
      when nil
      else ARGV << item
      end
    end

    case RUBY_VERSION
    when /1\.9\.[321]/
      ARGV.each { |file| require File.join(Dir.pwd, file) }
      ::MiniTest::Unit.new.run
    else
      puts "Unknown ruby version, don't know how to proceed"
    end
  end
end
