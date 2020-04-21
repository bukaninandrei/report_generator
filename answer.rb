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
require 'pry'
require 'date'
require 'minitest/autorun'
require 'benchmark'

# Report generator
class ReportGenerator
  DELIMITER = ','
  LITERAL_U = 'u'
  LITERAL_S = 's'
  TOTAL_SPENT_IDX = 1
  MAX_SPENT_IDX = 2
  TRUE_L = 'true'
  FALSE_L = 'false'

  class << self
    def generate(input_file = 'data_large.txt', output_file = 'answ/output.txt')
      instance = new
      puts Time.now
      instance.parse_data(input_file)
      puts Time.now
      instance.make_report(output_file)
      puts Time.now
      instance.clean_up
    end
  end

  def initialize
    clean_up
  end

  def clean_up
    @users = {}
    @sessions = {}
    @total_sessions_cnt = 0
    @uniq_browsers = {}
    @uniq_dates = {}
    @browser_ids = nil
  end

  def perform_user_row(line)
    _, id, f_name, l_name = line.split(DELIMITER)

    # full name, total session time, max session time
    @users[id.to_i] = ["#{f_name} #{l_name}", 0, 0]
  end

  def perform_session_row(line)
    _, u_id, _, browser, time, date = line.split(DELIMITER)
    uid = u_id.to_i

    store_user_timings(uid, time.to_i)
    store_common_stat(uid, browser, date)

    @total_sessions_cnt += 1
  end

  def store_user_timings(uid, time)
    @users[uid][TOTAL_SPENT_IDX] += time
    @users[uid][MAX_SPENT_IDX] = time if time > @users[uid][MAX_SPENT_IDX]
  end

  # pack user's session data to flat array: even items - browsers, odd - dates
  def store_common_stat(user_id, browser, date)
    # browsers map, sym -> id
    # dates map, sym, -> id

    @sessions[user_id] ||= []
    @sessions[user_id].push(
      @uniq_browsers[browser.to_sym] ||= @uniq_browsers.length,
      @uniq_dates[date.to_sym] ||= @uniq_dates.length
    )
  end

  def parse_data(file_name)
    file = File.open(file_name, 'r')

    parse_line(file.readline) until file.eof?

    file.close

    @uniq_browsers = @uniq_browsers.invert
    @uniq_dates = @uniq_dates.invert
  end

  def parse_line(line)
    case line[0]
    when LITERAL_S
      perform_session_row(line)
    when LITERAL_U
      perform_user_row(line)
    end
  end

  def prepare_browsers_cache
    @browser_ids = { ch: [], ie: [] }
    @uniq_browsers.each do |(k, v)|
      b = v.to_s
      @browser_ids[:ie] << k if b.index('Internet Explorer')
      @browser_ids[:ch] << k if b.index('Chrome')
    end
    @browser_ids[:ie].sort!
    @browser_ids[:ch].sort!
  end

  def make_report(file_name)
    prepare_browsers_cache

    file_out = File.open(file_name, 'w')

    draw_report_header(file_out)
    draw_report_body(file_out)
    draw_report_footer(file_out)

    file_out.close
  end

  def draw_report_body(file_out)
    @users.each_with_index do |(user_id, user), idx|
      user_session = @sessions[user_id]
      acc = prepare_item_data(user_session)

      file_out << DELIMITER if idx.positive?
      file_out << draw_report_item(user, acc, user_session.length)
    end
  end

  def draw_report_header(file_out)
    file_out << <<~TEXT
      {
        "allBrowsers": "#{@uniq_browsers.values.map(&:to_s).join(DELIMITER)}",
        "totalSessions": #{@total_sessions_cnt},
        "totalUsers": #{@users.length},
        "uniqueBrowsersCount": #{@uniq_browsers.length},
        "usersStats": {
    TEXT
  end

  def draw_report_footer(file_out)
    file_out << "}\n}"
  end

  def prepare_item_data(user_session)
    i = 0
    acc = { b: [], d: [], co: true, ie: false }
    while i < user_session.length
      browser_id = user_session[i]
      date_id = user_session[i + 1]
      i += 2

      acc[:b] << @uniq_browsers[browser_id]
      acc[:d] << @uniq_dates[date_id][0..9]

      if browser_present?(:ie, browser_id)
        acc[:ie] = true
        acc[:co] = false
        next
      end

      acc[:co] = false unless browser_present?(:ch, browser_id)
    end
    acc[:co] = false if acc[:b].empty?
    acc
  end

  # group: ch - chromes, ie - internet explorers
  def browser_present?(group, searchable_id)
    @browser_ids[group].bsearch_index { |bs| bs == searchable_id }
  end

  def draw_report_item(user, acc, sessions_count)
    joined_dates = acc[:d].empty? ? '' : "\"#{acc[:d].join('", "')}\""
    <<~TEXT
      "#{user[0]}": {
        "alwaysUsedChrome": #{bool_to_s(acc[:co])},
        "browsers": "#{acc[:b].join(DELIMITER)}",
        "dates": [#{joined_dates}],
        "longestSession": "#{user[MAX_SPENT_IDX]}",
        "sessionsCount": "#{sessions_count}",
        "totalTime": "#{user[TOTAL_SPENT_IDX]}",
        "usedIE": #{bool_to_s(acc[:ie])}
      }
    TEXT
  end

  def bool_to_s(val)
    val ? TRUE_L : FALSE_L
  end
end

# helper.rb
def print_memory_usage
  memory_before = `ps -o rss= -p #{Process.pid}`.to_i
  yield
  memory_after = `ps -o rss= -p #{Process.pid}`.to_i

  puts "Memory: #{((memory_after - memory_before) / 1024.0).round(2)} MB"
end

def print_time_spent
  time = Benchmark.realtime do
    yield
  end

  puts "Time: #{time}"
end

def measure(report)
  puts ' '
  puts report
  print_memory_usage do
    print_time_spent do
      yield
    end
  end
  puts ' '
end

# test
class TestMe < Minitest::Test
  def test_make
    measure('Test this') { ReportGenerator.generate }
  end
end
