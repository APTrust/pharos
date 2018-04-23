class Role < ActiveRecord::Base
  self.primary_key = 'id'
  validates :name, presence: true
end
