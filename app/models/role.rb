class Role < ActiveRecord::Base
  validates :name, presence: true
end
