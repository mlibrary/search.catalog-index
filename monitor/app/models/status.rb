class Status < ApplicationRecord
  belongs_to :job
  enum name: { started: 0 }
end
