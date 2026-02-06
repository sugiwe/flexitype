# frozen_string_literal: true

module TwitterShareable
  extend ActiveSupport::Concern

  private

  # X（旧Twitter）へのシェアURL
  def twitter_share_url(share)
    if share.period_summary?
      period_data = share.period_summary_data
      text = "【Typnix：#{share.period_display}の練習記録🦦】\n" \
             "練習回数: #{period_data[:count]}回\n" \
             "平均正答率: #{period_data[:avg_accuracy]}%\n" \
             "平均WPM: #{period_data[:avg_wpm]}\n" \
             "#typnix #タイピング"
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
