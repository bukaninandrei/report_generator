# frozen_string_literal: true

# rubocop:disable Style/AsciiComments
# Тут находится программа, выполняющая обработку данных из файла.
# Тест показывает как программа должна работать.
# В этой программе нужно обработать файл данных data_large.txt.

# Задача:
# Оптимизировать программу;
# Программа должна корректно обработать файл data_large.txt;
# Провести рефакторинг при необходимости
# Представить время обработки до и после
# rubocop:enable Style/AsciiComments

require 'json'
require 'minitest/autorun'
require 'benchmark'

require_relative 'lib/helpers'
require_relative 'lib/report_constants'
require_relative 'lib/report_parser'
require_relative 'lib/report_generator'

# Do all job together
module Staff
  def self.generate(input_file, output_file)
    reporter = ReportGenerator.new(output_file, ReportParser.new(input_file))
    reporter.make_report(output_file)
  end
end

# test
class TestMe < Minitest::Test
  def test_make
    measure('Test this') do
      Staff.generate('data_large.txt', 'answ/output.txt')
    end
  end
end
