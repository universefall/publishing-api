class Translation
  include SupportingObject
  extend Forwardable

  def_delegators :content_item, :locale, :locale=
end
