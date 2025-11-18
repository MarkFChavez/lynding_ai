class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :role, presence: true, inclusion: { in: %w[owner] }

  def email
    email_address
  end
end
