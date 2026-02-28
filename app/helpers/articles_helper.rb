module ArticlesHelper
  def markdown(text)
    return "" if text.blank?

    renderer = Redcarpet::Render::HTML.new(
      filter_html: true,        # HTMLタグをエスケープ（XSS対策）
      safe_links_only: true,    # 安全なプロトコル（http/https）のみ許可
      hard_wrap: true,
      link_attributes: { target: "_blank", rel: "noopener noreferrer" }
    )

    markdown = Redcarpet::Markdown.new(
      renderer,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      space_after_headers: true,
      superscript: true,
      underline: true,
      highlight: true,
      footnotes: true
    )

    markdown.render(text).html_safe
  end
end
