# README

This is a system for monitoring the completion of sidekiq jobs. 

There are two api endpoints

```
post /api/v1/jobs
```

Which takes in the following parameters
|parameter| description |
|=========|============|
| job_id | the sidekiq job_id |
| arguments | the arguments used for the job |
| job_class | the class used for the job |

This will create a job, and will mark it as started

```
post /api/v1/jobs/:job_id/complete
```

This uses the sidekiq `job_id` to mark the job as done.

