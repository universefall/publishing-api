module SupportingObject
  extend ActiveSupport::Concern
  extend Forwardable

  def_delegators :content_item, :update_attributes!

  attr_reader :content_item

  def initialize(content_item)
    @content_item = content_item
  end

  class_methods do
    def find_by!(content_item:)
      new(content_item)
    end

    alias :find_by :find_by!

    def filter(scope, **kwargs)
      scope.where(**kwargs)
    end

    def join_content_items(scope)
      scope
    end
  end
end
