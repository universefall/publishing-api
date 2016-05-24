class Location
  include SupportingObject
  extend Forwardable

  def_delegators :content_item, :base_path, :base_path=
end
