# frozen_string_literal: true
require_relative 'boot'

# test
class TestMe < Minitest::Test
  def test_timings
    measure('Test this') do
      input_file = 'data_large.txt'
      output_file = 'result.json'

      assert File.exist?(input_file)

      reporter = ReportGenerator.new(output_file, ReportParser.new(input_file))
      reporter.make_report

      assert !File.empty?(output_file)
    end
  end
end
