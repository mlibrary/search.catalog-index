FactoryBot.define do
  factory :job do
    queue { "queue" }
    arguments { "arguments" }
    job_id {"job_id"}
    job_class {"job_class"}

    factory :started_job do
      after(:create) do |job|
        create(:status, job: job)
      end
    end
    factory :completed_job do
      after(:create) do |job|
        create(:status, job: job, name: "complete")
      end
    end
  end

  factory :status do
    job
    name { "started" }
  end
end
