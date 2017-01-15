class Credential < ApplicationRecord
  has_many :usages
  belongs_to :account
end
