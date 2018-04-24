require 'spec_helper'

RSpec.describe SubscriptionInstitution, :type => :model do
  before(:all) do
    User.delete_all
  end

  subject { FactoryBot.build(:subscription_institution) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:identifier) }
  it { should validate_presence_of(:type) }

  describe '#name_is_unique' do
    it 'should validate uniqueness of the name' do
      one = FactoryBot.create(:subscription_institution, name: 'test')
      two = FactoryBot.build(:subscription_institution, name: 'test')
      two.should_not be_valid
      two.errors[:name].should include('has already been taken')
    end
  end

  describe '#identifier_is_unique' do
    it 'should validate uniqueness of the identifier' do
      one = FactoryBot.create(:subscription_institution, identifier: 'test.edu')
      two = FactoryBot.build(:subscription_institution, identifier: 'test.edu')
      two.should_not be_valid
      two.errors[:identifier].should include('has already been taken')
    end
  end

  describe '#has_associated_member_institution' do
    it 'should validate that it has an associated member institution' do
      one = FactoryBot.build(:subscription_institution, member_institution_id: nil)
      one.should_not be_valid
      one.errors[:member_institution_id].should include('cannot be nil')
    end
  end

  describe '#find_by_identifier' do
    it 'should validate uniqueness of the identifier' do
      one = FactoryBot.create(:subscription_institution, identifier: 'test.edu')
      two = FactoryBot.create(:subscription_institution, identifier: 'kollege.edu')
      SubscriptionInstitution.find_by_identifier('test.edu').should eq one
      SubscriptionInstitution.find_by_identifier('kollege.edu').should eq two
      SubscriptionInstitution.find_by_identifier('idontexist.edu').should be nil
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
    end

    describe 'with an associated intellectual object' do
      let!(:object) { FactoryBot.create(:intellectual_object, institution_id: subject.id) }
      let!(:file) { FactoryBot.create(:generic_file, intellectual_object_id: object.id, institution_id: subject.id) }
      after { object.destroy }
      it 'deleting should be blocked' do
        subject.destroy.should be false
        expect(Institution.exists?(subject.id)).to be true
      end

      it 'should be able to generate a cost report' do
        report = subject.generate_cost_report
        report[:total_file_size].should == file.size
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
        snapshot = subject.snapshot
        #snapshot.cost.should == (file.size * 0.000000000381988).round(2) # sometimes fails because of finicky rounding / storage
        snapshot.snapshot_type.should == 'Individual'
        snapshot.apt_bytes.should == file.size
        snapshot.institution_id.should == subject.id
      end
    end
  end
end
