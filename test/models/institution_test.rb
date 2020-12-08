# == Schema Information
#
# Table name: institutions
#
#  id                    :integer          not null, primary key
#  name                  :string
#  identifier            :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  state                 :string
#  type                  :string
#  member_institution_id :integer
#  deactivated_at        :datetime
#  otp_enabled           :boolean
#  receiving_bucket      :string           not null
#  restore_bucket        :string           not null
#
require 'test_helper'

class InstitutionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
