class Chat < ApplicationRecord
  belongs_to :application
  has_many :messages, dependent: :destroy

  validates :number, presence: true, uniqueness: { scope: :application_id }

  before_create :set_chat_number
  
  private

  def set_chat_number
    max_number = application.chats.maximum(:number) || 0
    self.number = max_number + 1
  end
  
end