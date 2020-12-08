# == Schema Information
#
# Table name: storage_records
#
#  id              :bigint           not null, primary key
#  generic_file_id :integer
#  url             :string
#
class StorageRecord < ApplicationRecord
  belongs_to :generic_file

  validates_presence_of :url
  validates_uniqueness_of :url

end
