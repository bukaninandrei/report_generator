# frozen_string_literal: true

# Data parser
class ReportParser
  include ReportConstants

  def initialize(input_file)
    @users = {}
    @sessions = {}
    @total_sessions_cnt = 0
    @uniq_browsers = {}
    @uniq_dates = {}
    @browser_ids = { ch: [], ie: [] }
    @file_name = input_file
  end

  def each_record
    @users.each_with_index do |(user_id, user), idx|
      yield(user, @sessions[user_id], idx)
    end
  end

  def counters(code)
    return @users.length if code == :users_cnt
    return @total_sessions_cnt if code == :total_sessions_cnt
    return @uniq_browsers.length if code == :browsers_cnt

    0
  end

  def parse_data
    file = File.open(@file_name, 'r')
    parse_line(file.readline) until file.eof?
    file.close

    prepare_data_for_caches
    prepare_browsers_cache
  end

  def browsers_to_s
    @uniq_browsers.values.map(&:to_s).join(DELIMITER)
  end

  def get_browser_by_id(id)
    @uniq_browsers[id]
  end

  def get_date_by_id(id)
    @uniq_dates[id]
  end

  def browsers_map
    @uniq_browsers
  end

  # group: ch - chrome instances, ie - internet explorers
  def browser_present?(group, searchable_id)
    @browser_ids[group].bsearch_index { |bs| bs == searchable_id }
  end

  private

  def prepare_browsers_cache
    @uniq_browsers.each do |(k, v)|
      b = v.to_s
      @browser_ids[:ie] << k if b.index('Internet Explorer')
      @browser_ids[:ch] << k if b.index('Chrome')
    end
    @browser_ids[:ie].sort!
    @browser_ids[:ch].sort!
  end

  def prepare_data_for_caches
    @uniq_browsers = @uniq_browsers.invert
    @uniq_dates = @uniq_dates.invert
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

  def parse_line(line)
    case line[0]
    when LITERAL_S
      perform_session_row(line)
    when LITERAL_U
      perform_user_row(line)
    end
  end
end
