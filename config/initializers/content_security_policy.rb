# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none

    # Google Tag Manager, Google Analytics, Google AdSense用のスクリプト許可
    policy.script_src  :self, :https, :unsafe_inline,
                       "https://accounts.google.com",
                       "https://www.googletagmanager.com",
                       "https://www.google-analytics.com",
                       "https://ssl.google-analytics.com",
                       "https://pagead2.googlesyndication.com",
                       "https://adservice.google.com"

    # Google関連サービス用のスタイル許可
    policy.style_src   :self, :https, :unsafe_inline

    # Google Analytics、AdSense用のコネクト許可
    policy.connect_src :self,
                       "https://www.google-analytics.com",
                       "https://analytics.google.com",
                       "https://stats.g.doubleclick.net",
                       "https://pagead2.googlesyndication.com"

    # Google AdSense用のフレーム許可
    policy.frame_src   :self,
                       "https://accounts.google.com",
                       "https://www.googletagmanager.com",
                       "https://bid.g.doubleclick.net",
                       "https://googleads.g.doubleclick.net",
                       "https://tpc.googlesyndication.com"

    # Specify URI for violation reports
    # policy.report_uri "/csp-violation-report-endpoint"
  end

  # Generate session nonces for permitted importmap, inline scripts, and inline styles.
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[script-src style-src]

  # Report violations without enforcing the policy.
  # 本番環境で問題が発生した場合は、一時的にこれを有効にしてデバッグ
  # config.content_security_policy_report_only = true
end
