class ReferralAgent < ApplicationRecord
  has_many :loans, dependent: :nullify

  validates :name, presence: true
  validates :commission_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100, allow_blank: true }
end
