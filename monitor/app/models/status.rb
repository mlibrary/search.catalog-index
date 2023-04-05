class Status < ApplicationRecord
  belongs_to :job
  enum name: { started: 0, complete: 1 }
end
