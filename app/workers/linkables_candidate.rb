require "async_experiments/candidate_worker"

class LinkablesCandidate < AsyncExperiments::CandidateWorker
  def perform(document_type, experiment)
    experiment_candidate(experiment) do
      Queries::GetLinkables.new(
        document_type: document_type,
      ).call
    end
  end
end
