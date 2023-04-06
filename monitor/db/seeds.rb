# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)
#
job = Job.create(
  job_id: "jid1", 
  arguments: "[\"search_daily_bibs/birds_2022021017_21131448650006381_new.tar.gz\",\"http://solr:8026/solr/biblio\"]", 
  job_class: "IndexIt",
  queue: "default"
)
Status.create(job: job, name: "started")
