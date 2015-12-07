module Queries
  module GetLinkSet
    def self.call(content_id)
      link_set = LinkSet.find_or_initialize_by(content_id: content_id)
      version = Version.find_or_initialize_by(target: link_set)
      Presenters::Queries::LinkSetPresenter.new(link_set, version).present
    end
  end
end
