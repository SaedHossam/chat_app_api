class Application < ApplicationRecord
  before_create :generate_token
  
  has_many :chats, dependent: :destroy

  private

  def generate_token
    self.token = SecureRandom.hex(16) # Generates a random 16-character token
  end
end
