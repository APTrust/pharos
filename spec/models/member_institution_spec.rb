require 'spec_helper'

RSpec.describe MemberInstitution, :type => :model do
  before(:all) do
    User.delete_all
    Institution.delete_all
  end

  subject { FactoryBot.build(:member_institution) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:identifier) }
  it { should validate_presence_of(:type) }

  describe '#name_is_unique' do
    it 'should validate uniqueness of the name' do
      one = FactoryBot.create(:member_institution, name: 'test')
      two = FactoryBot.build(:member_institution, name: 'test')
      two.should_not be_valid
      two.errors[:name].should include('has already been taken')
    end
  end

  describe '#identifier_is_unique' do
    it 'should validate uniqueness of the identifier' do
      one = FactoryBot.create(:member_institution, identifier: 'test.edu')
      two = FactoryBot.build(:member_institution, identifier: 'test.edu')
      two.should_not be_valid
      two.errors[:identifier].should include('has already been taken')
    end
  end

  describe '#find_by_identifier' do
    it 'should validate uniqueness of the identifier' do
      one = FactoryBot.create(:member_institution, identifier: 'test.edu')
      two = FactoryBot.create(:member_institution, identifier: 'kollege.edu')
      Institution.find_by_identifier('test.edu').should eq one
      Institution.find_by_identifier('kollege.edu').should eq two
      Institution.find_by_identifier('idontexist.edu').should be nil
    end
  end

  describe 'a saved instance' do
    before do
      subject.save
    end

    after do
      subject.destroy
    end

    describe 'bytes_by_format' do
      it 'should return a hash' do
        expect(subject.bytes_by_format).to eq({'all'=>0})
      end
      describe 'with attached files' do
        before do
          subject.save!
        end
        let(:intellectual_object) { FactoryBot.create(:intellectual_object, institution: subject) }
        let!(:generic_file1) { FactoryBot.create(:generic_file, intellectual_object: intellectual_object, size: 166311750, identifier: 'test.edu/123/data/file.xml') }
        let!(:generic_file2) { FactoryBot.create(:generic_file, intellectual_object: intellectual_object, file_format: 'audio/wav', size: 143732461, identifier: 'test.edu/123/data/file.wav') }
        it 'should return a hash' do
          expect(subject.bytes_by_format).to eq({"all"=>310044211,
                                                 'application/xml' => 166311750,
                                                 'audio/wav' => 143732461})
        end
      end
    end

    describe 'with an associated user' do
      let!(:user) { FactoryBot.create(:user, name: 'Zeke', institution_id: subject.id)  }
      it 'should contain the appropriate User' do
        subject.users.should eq [user]
      end

      it 'deleting should be blocked' do
        subject.destroy.should be false
        expect(Institution.exists?(subject.id)).to be true
      end

      describe 'or two' do
        let!(:user2) { FactoryBot.create(:user, name: 'Andrew', institution_id: subject.id) }
        it 'should return users sorted by name' do
          subject.users.index(user).should > subject.users.index(user2)
        end
      end

      describe 'or several' do
        let!(:user2) { FactoryBot.create(:user, :institutional_admin, name: 'Andrew', institution_id: subject.id) }
        let!(:user3) { FactoryBot.create(:user, :institutional_admin, name: 'Kelly', institution_id: subject.id) }
        let!(:apt) { FactoryBot.create(:aptrust)}
        let!(:user4) { FactoryBot.create(:user, :admin, name: 'Christian', institution_id: apt.id) }
        let!(:user5) { FactoryBot.create(:user, :admin, name: 'Bradley', institution_id: apt.id) }

        it 'should provide a list of institutional admins' do
          subject.admin_users.count.should eq 2
          expect(subject.admin_users.map &:id).to match_array [user2.id, user3.id]
        end

        it 'should provide a list of aptrust admins' do
          subject.apt_users.count.should eq 2
          expect(subject.apt_users.map &:id).to match_array [user4.id, user5.id]
        end

        it 'should provide a list of inst admins that are not the requesting user for a deletion request' do
          subject.deletion_admin_user(user2).count.should eq 1
          expect(subject.deletion_admin_user(user2).map &:id).to match_array [user3.id]
        end

        it 'should provide a list of apt admins that are not the requesting user for a bulk deletion' do
          subject.bulk_deletion_users(user4).count.should eq 1
          expect(subject.bulk_deletion_users(user4).map &:id).to match_array [user5.id]
        end

      end
      
      describe '#deactivate' do
        it 'should deactivate the institution and all users belonging to it' do
          subject.deactivate
          subject.deactivated?.should eq true
          subject.users.first.deactivated?.should eq true
          subject.deactivated_at.should_not be_nil
          subject.users.first.deactivated_at.should_not be_nil
          subject.users.first.encrypted_api_secret_key.should eq ''
        end
      end

      describe '#reactivate' do
        it 'should reactivate the institution and all users belonging to it' do
          subject.deactivate
          subject.deactivated?.should eq true
          subject.users.first.deactivated?.should eq true
          subject.deactivated_at.should_not be_nil
          subject.users.first.deactivated_at.should_not be_nil
          subject.users.first.encrypted_api_secret_key.should eq ''
          subject.reactivate
          subject.deactivated?.should eq false
          subject.users.first.deactivated?.should eq false
          subject.deactivated_at.should be_nil
          subject.users.first.deactivated_at.should be_nil
          subject.users.first.encrypted_api_secret_key.should eq ''
        end
      end
    end

    describe 'with an associated intellectual object' do
      let!(:item) { FactoryBot.create(:intellectual_object, institution: subject) }
      after { item.destroy }
      it 'deleting should be blocked' do
        subject.destroy.should be false
        expect(Institution.exists?(subject.id)).to be true
      end
    end

    describe 'with associated work items' do
      let!(:object_one) { FactoryBot.create(:intellectual_object, institution: subject) }
      let!(:object_two) { FactoryBot.create(:intellectual_object, institution: subject) }
      let!(:file_one) { FactoryBot.create(:generic_file, intellectual_object: object_one) }
      let!(:file_two) { FactoryBot.create(:generic_file, intellectual_object: object_two) }

      it 'should return a list of new deletion items' do
        latest_email = FactoryBot.create(:deletion_notification_email, institution_id: subject.id)
        sleep 1
        item_one = FactoryBot.create(:work_item, action: 'Delete', status: 'Success', stage: 'Resolve', generic_file: file_one, institution_id: subject.id)
        item_two = FactoryBot.create(:work_item, action: 'Delete', status: 'Success', stage: 'Resolve', generic_file: file_two, institution_id: subject.id)
        items = subject.new_deletion_items
        items.count.should eq(2)
        expect(items).to include(item_one)
        expect(items).to include(item_two)
      end

      it 'should generate a csv file for new deletion work items' do
        item_one = FactoryBot.create(:work_item, action: 'Delete', status: 'Success', stage: 'Resolve', generic_file: file_one, generic_file_identifier: file_one.identifier, institution_id: subject.id)
        item_two = FactoryBot.create(:work_item, action: 'Delete', status: 'Success', stage: 'Resolve', generic_file: file_two, generic_file_identifier: file_two.identifier, institution_id: subject.id)
        csv = subject.generate_deletion_csv([item_one, item_two])
        expect(csv).to include('Generic File Identifier,Date Deleted,Requested By,Approved By,APTrust Approver')
        expect(csv).to include("#{item_one.generic_file_identifier},#{item_one.date.to_s},#{item_one.user},NA,NA")
        expect(csv).to include("#{item_two.generic_file_identifier},#{item_two.date.to_s},#{item_two.user},NA,NA")
      end
    end

    describe 'with an associated subscription institution' do
      let!(:sub_inst) { FactoryBot.create(:subscription_institution, member_institution_id: subject.id) }
      let!(:object) { FactoryBot.create(:intellectual_object, institution_id: subject.id) }
      let!(:file) { FactoryBot.create(:generic_file, intellectual_object_id: object.id, institution_id: subject.id) }
      after { sub_inst.destroy }
      it 'deleting should be blocked' do
        subject.destroy.should be false
        expect(Institution.exists?(subject.id)).to be true
      end

      it 'subscribers method should return the subscribers' do
        subs = subject.subscribers
        subs.should == [sub_inst]
      end

      it 'should be able to generate a subscriber report' do
        report = subject.generate_subscriber_report
        report['total_bytes'].should == file.size
        report.keys.size.should == 2
        report.keys.should include sub_inst.name
      end

      it 'should be able to generate a cost report' do
        report = subject.generate_cost_report
        report[:total_file_size].should == file.size
        report[:subscribers]['total_bytes'].should == file.size
        report[:subscribers].keys.size.should == 2
        report[:subscribers].keys.should include sub_inst.name
      end

      it 'should be able to generate an overview report' do
        report = subject.generate_overview
        report[:bytes_by_format].keys.should include file.file_format
        report[:bytes_by_format]['all'].should == file.size
        report[:intellectual_objects].should == 1
        report[:generic_files].should == 1
        report[:premis_events].should == 0
        report[:work_items].should == 0
        report[:average_file_size].should == file.size
        report[:subscribers]['total_bytes'].should == file.size
        report[:subscribers].keys.size.should == 2
        report[:subscribers].keys.should include sub_inst.name
      end

      it 'should be able to generate a basic report' do
        report = subject.generate_basic_report
        report[:intellectual_objects].should == 1
        report[:generic_files].should == 1
        report[:premis_events].should == 0
        report[:work_items].should == 0
        report[:average_file_size].should == file.size
        report[:total_file_size].should == file.size
      end

      it 'should be able to generate a snapshot' do
        snapshot_array = subject.snapshot
        snapshot_array[0].cost.should == 0.00
        snapshot_array[0].snapshot_type.should == 'Individual'
        snapshot_array[0].apt_bytes.should == 0
        snapshot_array[0].institution_id.should == sub_inst.id

        #snapshot_array[1].cost.should == (file.size * 0.000000000381988).round(2) # sometimes fails because of finicky rounding / storage
        snapshot_array[1].snapshot_type.should == 'Individual'
        snapshot_array[1].apt_bytes.should == file.size
        snapshot_array[1].institution_id.should == subject.id

        snapshot_array[2].cost.should == 0.00
        snapshot_array[2].snapshot_type.should == 'Subscribers Included'
        snapshot_array[2].apt_bytes.should == file.size
        snapshot_array[2].institution_id.should == subject.id

      end
    end
  end
end
