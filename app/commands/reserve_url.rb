module Commands
  class ReserveUrl < BaseCommand
    def call
      UrlReservation.reserve_base_path!(base_path, payload[:publishing_app])
      Success.new(payload)
    end
  end
end
