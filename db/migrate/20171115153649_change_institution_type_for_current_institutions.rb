class ChangeInstitutionTypeForCurrentInstitutions < ActiveRecord::Migration[5.1]
  def change
    def up
      Institution.all.each do |inst|
        puts "Retyping #{inst.name} to be a member institution."
        inst.type = 'MemberInstitution'
        inst.save!
      end
    end
  end
end
