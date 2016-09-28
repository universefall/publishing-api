require "diffy"

module DataHygiene
  class GovspeakCompare
    attr_reader :content_item

    def initialize(content_item)
      @content_item = content_item
    end

    def published_html
      @published_html ||= format_published_html
    end

    def generated_html
      @generated_html ||= html_from_details(
        Presenters::DetailsPresenter.new(content_item.details_for_govspeak_conversion).details
      )
    end

    def diffs
      @diffs ||= calculate_diffs
    end

    def same_html?
      HashDiff.diff(published_html, generated_html) == []
    end

    def pretty_much_same_html?
      return true if same_html?
      diffs.all? { |_, diff| diff == [] }
    end

  private

    def calculate_diffs
      keys = (published_html.keys + generated_html.keys).uniq.sort
      keys.each_with_object({}) do |key, memo|
        memo[key] = html_diff(published_html[key], generated_html[key])
      end
    end

    def html_diff(old_html, new_html)
      diff = Diffy::Diff.new(old_html, new_html, context: 1)

      diff = diff.reject { |s| s.match(/^ /) || s.match(/^(\+|-)$/) }

      diff.reject do |s|
        check = (s[0] == "+" ? "-" : "+") + s[1..-1]
        diff.any? { |elem| basically_match(elem) == basically_match(check) }
      end
    end

    def basically_match(s)
      s.gsub(/<span.+class=\"attachment\-inline\">(.+)<\/span>/, '\1') #span tags
        .gsub(/(rel="external"|class="last-child")/, "") #common attributes
        .gsub(/\s+/, "") #whitespace
    end

    def format_published_html
      html_details = html_from_details(content_item.details)
      html_details.each_with_object({}) do |(key, value), memo|
        # pushed through nokogiri to catch minor html differences (<br /> -> <br>, unicode characters)
        memo[key] = Nokogiri::HTML.fragment(value).to_html
      end
    end

    def html_from_details(details)
      details.each_with_object({}) do |(key, value), memo|
        wrapped = Array.wrap(value)
        html = wrapped.find do |item|
          item.is_a?(Hash) && item[:content_type] == "text/html"
        end
        memo[key] = html[:content] if html && html[:content]
      end
    end
  end
end
