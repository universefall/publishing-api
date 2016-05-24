class UserFacingVersion
  include SupportingObject
  extend Forwardable

  def_delegators :content_item, :number, :number=

  def self.latest(content_item_scope)
    content_item_scope
      .order("number asc")
      .last
  end

  def increment
    self.number += 1
  end
end
