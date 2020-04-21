# frozen_string_literal: true

# Report generator
class ReportGenerator
  include ReportConstants

  def initialize(output_file, parser)
    @parser = parser
    @file_name = output_file
  end

  def make_report(file_name)
    @parser.parse_data

    file_out = File.open(file_name, 'w')

    draw_report_header(file_out)
    draw_report_body(file_out)
    draw_report_footer(file_out)

    file_out.close
  end

  private

  def draw_report_header(file_out)
    file_out << <<~TEXT
      {
        "allBrowsers": "#{@parser.browsers_to_s}",
        "totalSessions": #{@parser.counters(:total_sessions_cnt)},
        "totalUsers": #{@parser.counters(:users_cnt)},
        "uniqueBrowsersCount": #{@parser.counters(:browsers_cnt)},
        "usersStats": {
    TEXT
  end

  def draw_report_body(file_out)
    @parser.each_record do |user, session, idx|
      acc = prepare_item_data(session)

      file_out << DELIMITER if idx.positive?
      file_out << draw_report_item(user, acc, session.length)
    end
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

      acc[:b] << @parser.get_browser_by_id(browser_id)
      acc[:d] << @parser.get_date_by_id(date_id)[0..9]

      if @parser.browser_present?(:ie, browser_id)
        acc[:ie] = true
        acc[:co] = false
        next
      end

      acc[:co] = false unless @parser.browser_present?(:ch, browser_id)
    end
    acc[:co] = false if acc[:b].empty?
    acc
  end

  def bool_to_s(val)
    val ? TRUE_L : FALSE_L
  end
end
