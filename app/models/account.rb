class Account < ApplicationRecord
  has_many :usages
  has_one :credential
end
