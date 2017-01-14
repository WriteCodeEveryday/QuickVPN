class Credential < ApplicationRecord
  has_many :usages
  belongs_to :credential
end
