# Тут находится программа, выполняющая обработку данных из файла.
# Тест показывает как программа должна работать.
# В этой программе нужно обработать файл данных data_large.txt.

# Задача:
# Оптимизировать программу;
# Программа должна корректно обработать файл data_large.txt;
# Провести рефакторинг при необходимости
# Представить время обработки до и после

require 'json'
require 'pry'
require 'date'
require 'minitest/autorun'
require 'benchmark'

class ReportGenerator
  DELIMITER = ','.freeze
  LITERAL_U = 'u'.freeze
  LITERAL_S = 's'.freeze
  TOTAL_SPENT_IDX = 1
  MAX_SPENT_IDX = 2

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

  def initialize; clean_up end

  def clean_up
    @users = {}
    @sessions = {}
    @total_sessions_cnt = 0
    @uniq_browsers = {}
    @uniq_dates = {}
  end

  def perform_user(line)
    _, id, f_name, l_name, _ = line.split(DELIMITER)
    @users[id.to_i] = ["#{f_name} #{l_name}", 0, 0]
  end

  def perform_session(line)
    _, u_id, _, browser, time, date = line.split(DELIMITER)
    uid = u_id.to_i

    time = time.to_i
    @users[uid][TOTAL_SPENT_IDX] += time
    @users[uid][MAX_SPENT_IDX] = time if time > @users[uid][MAX_SPENT_IDX]

    # справочник браузеров, sym -> id
    browser_sym = browser.to_sym
    @uniq_browsers[browser_sym] ||= @uniq_browsers.length # browser sym to id map

    # справочник дат, sym, -> id
    date_sym = date.to_sym
    @uniq_dates[date_sym] ||= @uniq_dates.length

    # четные элементы это браузеры, нечетные - даты
    @sessions[uid] ||= []
    @sessions[uid].push(@uniq_browsers[browser_sym], @uniq_dates[date_sym])
    @total_sessions_cnt += 1
  end

  def parse_data(file_name)
    file = File.open(file_name, 'r')

    while file
      begin
        line = file.readline
        case line[0]
        when LITERAL_U
          perform_user(line)
        when LITERAL_S
          perform_session(line)
        else
          next
        end
      rescue EOFError
        break
      end
    end

    file.close
  end

  def make_report(file_name)
    @uniq_browsers = @uniq_browsers.invert
    @uniq_dates = @uniq_dates.invert

    chrome_ids = []
    i_explorer_ids = []
    @uniq_browsers.each do |(k, v)|
      b = v.to_s
      i_explorer_ids << k if b.index('Internet Explorer')
      chrome_ids << k if b.index('Chrome')
    end
    chrome_ids.sort!
    i_explorer_ids.sort!

    file_out = File.open(file_name, 'w')
    file_out << <<~TEXT
    {
      "allBrowsers": "#{@uniq_browsers.values.map(&:to_s).join(DELIMITER)}",
      "totalSessions": #{@total_sessions_cnt},
      "totalUsers": #{@users.length},
      "uniqueBrowsersCount": #{@uniq_browsers.length},
      "usersStats": {
    TEXT

    is_first = true
    true_literal = 'true'
    false_literal = 'false'

    @users.each do |(user_id, user)|
      i = 0
      acc = { b: [], d: [], co: true, ie: false }
      while i < @sessions[user_id].length do
        browser_id = @sessions[user_id][i]
        date_id = @sessions[user_id][i+1]

        acc[:d] << @uniq_dates[date_id][0..9]
        acc[:b] << @uniq_browsers[browser_id]

        if i_explorer_ids.bsearch_index { |bs| bs == browser_id }
          acc[:ie] = true
          acc[:co] = false
        else
          acc[:co] = false unless chrome_ids.bsearch_index { |bs| bs == browser_id }
        end

        i += 2
      end
      acc[:co] = false if acc[:b].empty?

      joined_dates = acc[:d].empty? ? '' : ("\"#{acc[:d].join('", "')}\"")
      file_out << DELIMITER unless is_first
      file_out << <<~TEXT
      "#{user[0]}": {
        "alwaysUsedChrome": #{acc[:co] ? true_literal : false_literal},
        "browsers": "#{acc[:b].join(DELIMITER)}",
        "dates": [#{joined_dates}],
        "longestSession": "#{user[MAX_SPENT_IDX]}",
        "sessionsCount": "#{@sessions[user_id].length}",
        "totalTime": "#{user[TOTAL_SPENT_IDX]}",
        "usedIE": #{acc[:ie] ? true_literal : false_literal}
      }
      TEXT

      is_first = false
    end

    file_out << '}}'
    file_out.close
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
  puts " "
  puts report
  print_memory_usage do
    print_time_spent do
      yield
    end
  end
  puts " "
end

# test
class TestMe < Minitest::Test
  def test_make
    measure('Test this') { ReportGenerator.generate }
  end
end