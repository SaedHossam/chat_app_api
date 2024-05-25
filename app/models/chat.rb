class Chat < ApplicationRecord
  belongs_to :application
  has_many :messages, dependent: :destroy

  validates :number, presence: true, uniqueness: { scope: :application_id }

  before_validation :set_chat_number, on: :create
  after_create :enqueue_update_chats_count

  private

  def set_chat_number
    max_number = application.chats.maximum(:number) || 0
    self.number = max_number + 1
  end
  
  def enqueue_update_chats_count
    UpdateChatsCountWorker.perform_async(application.id)
  end
end