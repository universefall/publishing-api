require "forwardable"

class WebContentItem
  CONTENT_ITEM_METHODS = %i{
    id content_id description analytics_identifier title base_path locale name number
  }

  FILTERABLE_ATTRIBUTES = {
    base_path: 'locations',
    locale: 'translations',
    name: 'states',
    number: 'user_facing_versions'
  }

  JOIN_SCOPE = ContentItem.joins(<<-SQL)
      INNER JOIN locations ON locations.content_item_id = content_items.id
      INNER JOIN states ON states.content_item_id = content_items.id
      INNER JOIN translations ON translations.content_item_id = content_items.id
      INNER JOIN user_facing_versions ON user_facing_versions.content_item_id = content_items.id
    SQL

  Record = Struct.new(*CONTENT_ITEM_METHODS) do
    def api_url
      return unless base_path
      Plek.current.website_root + "/api/content" + base_path
    end

    def web_url
      return unless base_path
      Plek.current.website_root + base_path
    end
  end

  class << self
    def get_by_id(id)
      JOIN_SCOPE.where(id: id).pluck(*CONTENT_ITEM_METHODS).map { |r| Record.new(*r) }.first
    end

    def get_by_content_id(content_id, **conditions)
      conditions = conditions.slice(*FILTERABLE_ATTRIBUTES.keys).map do |attribute, value|
        [FILTERABLE_ATTRIBUTES[attribute], {attribute => value}]
      end.to_h

      conditions.merge!(content_items: {content_id: content_id})

      scope = JOIN_SCOPE.where(conditions)
      FILTERABLE_ATTRIBUTES.keys.each do |attribute|
        scope = order_by_clause(scope, attribute, conditions[attribute])
      end

      scope.pluck(*CONTENT_ITEM_METHODS).map { |r| Record.new(*r) }
    end

  private

    def order_by_clause(scope, attribute, values)
      if Array(values).size > 1
        order_sql = "ORDER BY CASE #{FILTERABLE_ATTRIBUTES[attribute]}.#{attribute}\n"
        values.each_with_index do |value, i|
          order_sql << "WHEN '#{value}' THEN #{i}\n"
        end
        order_sql << 'END ASC'
        scope.order(order_sql)
      else
        scope
      end
    end
  end

end
