class ConfirmationToken < ActiveRecord::Base
  belongs_to :intellectual_object

  validates :intellectual_object, :token, presence: true
  before_save :generate_token

  private

  def generate_token
    self.token = SecureRandom.hex
  end
end