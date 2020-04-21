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
    joined_dates = acc[:dates].empty? ? '' : "\"#{acc[:dates].join('", "')}\""
    joined_browsers = acc[:browsers].join(DELIMITER)

    <<~TEXT
      "#{user[0]}": {
        "alwaysUsedChrome": #{bool_to_s(acc[:chrome_only])},
        "browsers": "#{joined_browsers}",
        "dates": [#{joined_dates}],
        "longestSession": "#{user[MAX_SPENT_IDX]}",
        "sessionsCount": "#{sessions_count}",
        "totalTime": "#{user[TOTAL_SPENT_IDX]}",
        "usedIE": #{bool_to_s(acc[:use_ie])}
      }
    TEXT
  end

  def draw_report_footer(file_out)
    file_out << "}\n}"
  end

  def prepare_item_data(user_sessions)
    acc = { browsers: [], dates: [], chrome_only: true, use_ie: false }
    @parser.each_session(user_sessions) do |browser_id, date_id|
      acc[:browsers] << @parser.get_browser_by_id(browser_id)
      acc[:dates] << @parser.get_date_by_id(date_id)[0..9]

      if @parser.browser_present?(:ie, browser_id)
        acc[:use_ie] = true
        acc[:chrome_only] = false
        next
      end
      acc[:chrome_only] = false unless @parser.browser_absent?(:ch, browser_id)
    end
    acc
  end

  def bool_to_s(val)
    val ? TRUE_L : FALSE_L
  end
end
