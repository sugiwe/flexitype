# frozen_string_literal: true

module TwitterShareable
  extend ActiveSupport::Concern

  private

  # X（旧Twitter）へのシェアURL
  def twitter_share_url(share)
    if share.period_summary?
      period_data = share.period_summary_data
      text = I18n.t("share.twitter_period_text",
        period: share.period_display,
        count: period_data[:count],
        avg_accuracy: period_data[:avg_accuracy],
        avg_wpm: period_data[:avg_wpm])
    else
      text = I18n.t("share.twitter_text",
        lesson: share.lesson_name,
        grade: share.grade_name,
        accuracy: share.accuracy,
        wpm: share.wpm)
    end
    url = share_url(share.token)
    "https://x.com/intent/post?text=#{CGI.escape(text)}&url=#{CGI.escape(url)}"
  end
end
