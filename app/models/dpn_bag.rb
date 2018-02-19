class DpnBag < ApplicationRecord
  belongs_to :institution

  validates :object_identifier, :dpn_identifier, presence: :true

  ### Scopes
  scope :with_institution, ->(param) { where(institution_id: param) unless param.blank? }
  scope :with_object_identifier, ->(param) { where(object_identifier: param) unless param.blank? }
  scope :with_dpn_identifier, ->(param) { where(dpn_identifier: param) unless param.blank? }
  scope :with_node_1, ->(param) { where(node_1: param) unless param.blank? }
  scope :with_node_2, ->(param) { where(node_2: param) unless param.blank? }
  scope :with_node_3, ->(param) { where(node_3: param) unless param.blank? }
  scope :created_before, ->(param) { where('dpn_bags.dpn_created_at < ?', param) unless param.blank? }
  scope :created_after, ->(param) { where('dpn_bags.dpn_created_at > ?', param) unless param.blank? }
  scope :updated_before, ->(param) { where('dpn_bags.dpn_updated_at < ?', param) unless param.blank? }
  scope :updated_after, ->(param) { where('dpn_bags.dpn_updated_at > ?', param) unless param.blank? }

  # We want this to always be true so that authorization happens in the user policy, preventing incorrect 404 errors.
  scope :readable, ->(current_user) { where('(1=1)') }

  def serializable_hash (options={})
    {
        id: id,
        institution_id: institution_id,
        object_identifier: object_identifier,
        dpn_identifier: dpn_identifier,
        dpn_size: dpn_size,
        node_1: node_1,
        node_2: node_2,
        node_3: node_3,
        dpn_created_at: dpn_created_at,
        dpn_updated_at: dpn_updated_at,
        created_at: created_at,
        updated_at: updated_at
    }
  end
end
