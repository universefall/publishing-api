class UrlReservationsController < ApplicationController
  def reserve_url
    render json: Command::ReserveUrl.call(base_path, publishing_app)
  end

private

  def base_path
    params[:base_path]
  end

  def publishing_app
    params[:publishing_app]
  end
end
