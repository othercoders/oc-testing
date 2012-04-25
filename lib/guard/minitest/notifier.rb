require 'guard/notifier'

module Guard
  module MinitestNotifier
    def self.notify(test_count, assertion_count, failures, errors, skips, duration)
      image, message = if failures > 0 || errors > 0
                         [:failed, "#{failures} failure#{'s' if failures > 1}, #{errors} error#{'s' if errors > 1}, #{skips} pending "]
                       elsif skips > 0
                         [:pending, "#{skips} pending"]
                       else
                         [:success, "#{test_count} passing test#{'s' if test_count > 1} with #{assertion_count} assertion#{'s' if assertion_count > 1}"]
                       end

      Guard::Notifier.notify message, title: 'Test Results', image: image
    end
  end
end
