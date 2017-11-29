class ConfirmationToken < ActiveRecord::Base
  belongs_to :intellectual_object

  validates :intellectual_object, :token, presence: true
  before_save :init_token

  private
  def init_token
    self.token = SecureRandom.hex if self.token.nil?
  end
end