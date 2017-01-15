class Usage < ApplicationRecord
  belongs_to :credential
  belongs_to :account
end
