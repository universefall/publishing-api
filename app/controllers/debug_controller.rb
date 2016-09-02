class DebugController < ApplicationController
  skip_before_action :require_signin_permission!
  before_action :validate_experiment_name, only: [:experiment]

  def show
    @presenter = Presenters::DebugPresenter.new(params[:content_id])
  end

  def experiment
    @mismatched_responses = AsyncExperiments.get_experiment_data(params[:experiment])
  end

private

  def validate_experiment_name
    raise "Experiment names don't contain `:`" if params[:experiment].include?(":")
  end
end
