class Spork::TestFramework::MiniTest < Spork::TestFramework
  DEFAULT_PORT = 8988
  HELPER_FILE = File.join(Dir.pwd, 'test/test_helper.rb')

  def run_tests(argv, stderr, stdout)
    # Redirect all test output back to spork
    ::MiniTest::Unit.output = stdout

    # MiniTest's test/unit does not support -I
    ARGV.clear
    argv.each do |item|
      if item =~ /-I(.*)/
        $1.split(File::PATH_SEPARATOR).each { |path| $:.unshift path.strip }
        true
      else
        ARGV << item
      end
    end

    # Find the builtin testrb executable and let it run the tests
    path = ENV['PATH'].split(File::PATH_SEPARATOR).detect do |path|
      File.exists?(File.join(path, 'testrb'))
    end
    load File.join(path, 'testrb')

    ::MiniTest::Unit.new.run(ARGV)
  end
end
