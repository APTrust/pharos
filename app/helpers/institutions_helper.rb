module InstitutionsHelper

  def member_institutions_for_select
    MemberInstitution.all.order('name').select {|institution| policy(institution).new? }
  end

  def types_for_select
    %w(MemberInstitution SubscriptionInstitution)
  end

end
