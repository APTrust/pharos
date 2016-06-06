require 'spec_helper'

RSpec.describe GenericFile, :type => :model do

  it 'delegates institution to the intellectual object' do
    file = FactoryGirl.create(:generic_file)
    institution = file.intellectual_object.institution
    file.institution.should == institution
  end

  it { should validate_presence_of(:uri) }
  it { should validate_presence_of(:size) }
  it { should validate_presence_of(:created) }
  it { should validate_presence_of(:modified) }
  it { should validate_presence_of(:file_format) }
  it { should validate_presence_of(:identifier)}

  it 'should validate presence of intellectual object' do
    file = FactoryGirl.create(:generic_file)
    expect(file.intellectual_object).to be_valid
    expect(file.intellectual_object.identifier).to include('/')
  end

  it 'should validate presence of a checksum' do
    expect(subject.valid?).to be false
    expect(subject.errors[:checksums]).to eq ["can't be blank"]
    subject.checksums.push( FactoryGirl.create(:checksum, digest: '1234') )
    expect(subject.valid?).to be false
    expect(subject.errors[:checksums]).to be_empty
  end

  describe '#identifier_is_unique' do
    it 'should validate uniqueness of the identifier' do
      one = FactoryGirl.create(:generic_file, identifier: 'test.edu')
      two = FactoryGirl.build(:generic_file, identifier: 'test.edu')
      two.should_not be_valid
      two.errors[:identifier].should include('has already been taken')
    end
  end

  describe 'with an intellectual object' do
    before do
      subject.intellectual_object = intellectual_object
    end

    let(:institution) { mock_model Institution, internal_uri: 'info:fedora/testing:123', name: 'Mock Name' }
    let(:intellectual_object) { mock_model IntellectualObject, institution: institution, identifier: 'info:fedora/testing:123/1234567' }

    describe '#find_latest_fixity_check' do
      subject { FactoryGirl.create(:generic_file) }
      it 'should return the most recent fixity check' do
        date = '2014-08-01T16:33:39Z'
        date_two = '2014-11-01T16:33:39Z'
        date_three = '2014-10-01T16:33:39Z'
        subject.add_event(FactoryGirl.attributes_for(:premis_event_fixity_check, date_time: date))
        subject.add_event(FactoryGirl.attributes_for(:premis_event_fixity_check, date_time: date_two))
        subject.add_event(FactoryGirl.attributes_for(:premis_event_fixity_check, date_time: date_three))
        puts "Event check: #{subject.premis_events.count}"
        subject.find_latest_fixity_check.should == date_two
      end
    end

    describe 'that is saved' do
      #TODO: figure out how to replace hydra access permissions
      # let(:intellectual_object) { FactoryGirl.create(:intellectual_object) }
      # subject { FactoryGirl.build(:generic_file, intellectual_object: intellectual_object) }
      # describe 'permissions' do
      #   before do
      #     intellectual_object.permissions = [
      #         Hydra::AccessControls::Permission.new(:name=>'institutional_admin', :access=>'read', :type=>'group'),
      #         Hydra::AccessControls::Permission.new(:name=>'institutional_user', :access=>'read', :type=>'group'),
      #         Hydra::AccessControls::Permission.new(:name=>'Admin_At_aptrust-test_22953', :access=>'edit', :type=>'group')]
      #   end
      #   after do
      #     subject.destroy
      #     intellectual_object.destroy
      #   end
      #   it 'should copy the permissions of the intellectual object it belongs to' do
      #     subject.save!
      #     subject.permissions.should == [
      #         Hydra::AccessControls::Permission.new(:name=>'institutional_admin', :access=>'read', :type=>'group'),
      #         Hydra::AccessControls::Permission.new(:name=>'institutional_user', :access=>'read', :type=>'group'),
      #         Hydra::AccessControls::Permission.new(:name=>'Admin_At_aptrust-test_22953', :access=>'edit', :type=>'group')]
      #   end
      # end
      # describe 'its intellectual_object' do
      #   after(:all)do # Must use after(:all) to avoid 'can't modify frozen Class' bug in rspec-mocks
      #     subject.destroy
      #     intellectual_object.destroy
      #   end
      # end

      describe 'soft_delete' do
        let(:object) { FactoryGirl.create(:intellectual_object) }
        let(:file) { FactoryGirl.create(:generic_file, intellectual_object: object) }
        before do
          file.save!
          @parent_work_item = FactoryGirl.create(:work_item,
                                                      object_identifier: file.intellectual_object.identifier,
                                                      action: Pharos::Application::PHAROS_ACTIONS['ingest'],
                                                      stage: Pharos::Application::PHAROS_STAGES['record'],
                                                      status: Pharos::Application::PHAROS_STATUSES['success'])
        end
        after do
          file.destroy
          intellectual_object.destroy
          @parent_work_item.delete
        end

        let(:async_job) { double('one') }

        it 'should set the state to deleted and index the object state' do

          expect {
            file.soft_delete(FactoryGirl.attributes_for(:premis_event_deletion, outcome_detail: 'joe@example.com'))
          }.to change { file.premis_events.count}.by(1)
          expect(file.state).to eq 'D'
        end

        it 'should create a WorkItem showing delete was requested' do
          file.soft_delete(FactoryGirl.attributes_for(:premis_event_deletion, outcome_detail: 'user@example.com'))
          pi = WorkItem.where(generic_file_identifier: file.identifier).first
          expect(pi).not_to be_nil
          expect(pi.object_identifier).to eq file.intellectual_object.identifier
          expect(pi.action).to eq Pharos::Application::PHAROS_ACTIONS['delete']
          expect(pi.stage).to eq Pharos::Application::PHAROS_STAGES['requested']
          expect(pi.status).to eq Pharos::Application::PHAROS_STATUSES['pend']
          expect(pi.user).to eq 'user@example.com'
        end

      end

      describe 'serializable_hash' do
        let(:subject) { FactoryGirl.create(:generic_file) }
        before do
        end
        after do
        end

        it 'should set the state to deleted and index the object state' do
          h1 = subject.serializable_hash
          expect(h1.has_key?(:id)).to be true
          expect(h1.has_key?(:uri)).to be true
          expect(h1.has_key?(:size)).to be true
          expect(h1.has_key?(:created)).to be true
          expect(h1.has_key?(:modified)).to be true
          expect(h1.has_key?(:file_format)).to be true
          expect(h1.has_key?(:identifier)).to be true
          expect(h1.has_key?(:state)).to be true

          h2 = subject.serializable_hash(include: [:checksums, :premis_events])
          expect(h2.has_key?(:id)).to be true
          expect(h2.has_key?(:uri)).to be true
          expect(h2.has_key?(:size)).to be true
          expect(h2.has_key?(:created)).to be true
          expect(h2.has_key?(:modified)).to be true
          expect(h2.has_key?(:file_format)).to be true
          expect(h2.has_key?(:identifier)).to be true
          expect(h2.has_key?(:state)).to be true
          expect(h2.has_key?(:checksums)).to be true
          expect(h2.has_key?(:premis_events)).to be true
        end
      end

      describe 'find_checksum_by_digest' do
        it 'should find the checksum' do
          subject.checksums.push(FactoryGirl.create(:checksum))
          digest = subject.checksums.first.digest
          expect(subject.find_checksum_by_digest(digest)).not_to be_nil
        end
        it 'should return nil for non-existent checksum' do
          expect(subject.find_checksum_by_digest(' :-{ ')).to be_nil
        end
      end

      describe 'has_checksum?' do
        it 'should return true if checksum is present' do
          subject.checksums.push(FactoryGirl.create(:checksum))
          digest = subject.checksums.first.digest
          expect(subject.has_checksum?(digest)).to be true
        end
        it 'should return false if checksum is not present' do
          expect(subject.has_checksum?(' :( ')).to be false
        end
      end

    end
  end

  describe '#find_files_in_need_of_fixity' do
    let(:subject) { FactoryGirl.create(:generic_file) }
    let(:subject_two) { FactoryGirl.create(:generic_file) }
    before do
      GenericFile.destroy_all
    end
    it 'should return only files with a fixity older than a given parameter' do
      date = '2014-01-01T16:33:39Z'
      date_two = '2014-12-12T16:33:39Z'
      param = '2014-09-02T16:33:39Z'
      subject.add_event(FactoryGirl.attributes_for(:premis_event_fixity_check, date_time: date))
      subject_two.add_event(FactoryGirl.attributes_for(:premis_event_fixity_check, date_time: date_two))
      files = GenericFile.find_files_in_need_of_fixity(param)
      count = 0
      files.each { count = count+1 }
      count.should == 1
      files.first.identifier.should == subject.identifier
    end
  end
end
