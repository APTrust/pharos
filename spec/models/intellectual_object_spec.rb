require 'spec_helper'

RSpec.describe IntellectualObject, :type => :model do
  before(:all) do
    IntellectualObject.destroy_all
  end

  it { should validate_presence_of(:title) }
  it { should validate_presence_of(:identifier) }
  it { should validate_presence_of(:institution) }
  it { should validate_presence_of(:access)}

  describe 'An instance' do

    it 'should properly set a title' do
      subject.title = 'War and Peace'
      subject.title.should == 'War and Peace'
    end

    it 'should properly set access' do
      subject.access = 'consortia'
      subject.access.should == 'consortia'
    end

    it 'must be one of the standard access' do
      subject.access = 'error'
      subject.should_not be_valid
    end

    it 'should properly set a description' do
      exp = Faker::Lorem.paragraph
      subject.description = exp
      subject.description.should == exp
    end

    it 'should properly set an identifier' do
      exp = SecureRandom.uuid
      subject.identifier = exp
      subject.identifier.should == exp
    end

    it 'should properly set an alternative identifier' do
      exp = 'test.edu/123456'
      subject.alt_identifier = exp
      subject.alt_identifier.should == exp
    end

    it 'should properly set a bag name' do
      exp = 'bag_name'
      subject.bag_name = exp
      subject.bag_name.should == exp
    end

    it 'should have terms_for_editing' do
      expect(subject.terms_for_editing).to eq [:title, :description, :access]
    end

  end

  describe 'bytes_by_format' do
    subject { FactoryGirl.create(:institutional_intellectual_object) }
    it 'should return a hash' do
      expect(subject.bytes_by_format).to eq({"all"=>0})
    end

    describe 'with attached files' do
      before do
        subject.generic_files << FactoryGirl.build(:generic_file, intellectual_object: subject, size: 166311750, identifier: 'test.edu/123/data/file.xml')
        subject.generic_files << FactoryGirl.build(:generic_file, intellectual_object: subject, file_format: 'audio/wav', size: 143732461, identifier: 'test.edu/123/data/file.wav')
        subject.save!
      end

      it 'should return a hash' do
        expect(subject.bytes_by_format).to eq({'all'=>310044211,
                                               'application/xml' => 166311750,
                                               'audio/wav' => 143732461})
      end
    end
  end

  describe 'A saved instance' do
    after { subject.destroy }

    describe 'with generic files' do
      after do
        subject.generic_files.destroy_all
      end

      subject { FactoryGirl.create(:intellectual_object) }

      before do
        @file = FactoryGirl.create(:generic_file, intellectual_object: subject)
        subject.reload
      end

      it 'test setup assumptions' do
        subject.id.should == subject.generic_files.first.intellectual_object_id
        subject.generic_files.should == [@file]
      end

      it 'should not be destroyable' do
        expect(subject.destroy).to be false
      end

      it 'should fill in an empty bag name with data from the identifier' do
        expect(subject.bag_name).to eq subject.identifier.split('/')[1]
      end

      describe 'soft_delete' do
        before {
          @work_item = FactoryGirl.create(:work_item,
                                               object_identifier: subject.identifier,
                                               action: Pharos::Application::PHAROS_ACTIONS['ingest'],
                                               stage: Pharos::Application::PHAROS_STAGES['record'],
                                               status: Pharos::Application::PHAROS_STATUSES['success'])
        }
        after {
          @work_item.delete
        }
        let(:intellectual_object_delete_job) { double('intellectual object') }
        let(:generic_file_delete_job) { double('file') }

        it 'should set the state to deleted and index the object state' do
          attributes = FactoryGirl.attributes_for(:premis_event_deletion, outcome_detail: 'joe@example.com')
          expect {
            subject.soft_delete(attributes)
          }.to change { subject.premis_events.count}.by(1)
          subject.background_deletion(attributes)
          expect(subject.state).to eq 'D'
          subject.generic_files.all?{ |file| expect(file.state).to eq 'D' }
        end

        it 'should set the state to deleted and index the object state' do
          attributes = FactoryGirl.attributes_for(:premis_event_deletion, outcome_detail: 'user@example.com')
          subject.soft_delete(attributes)
          subject.background_deletion(attributes)
          subject.generic_files.all?{ |file|
            wi = WorkItem.where(generic_file_identifier: file.identifier).first
            expect(wi).not_to be_nil
            expect(wi.object_identifier).to eq subject.identifier
            expect(wi.action).to eq Pharos::Application::PHAROS_ACTIONS['delete']
            expect(wi.stage).to eq Pharos::Application::PHAROS_STAGES['requested']
            expect(wi.status).to eq Pharos::Application::PHAROS_STATUSES['pend']
            expect(wi.user).to eq 'user@example.com'
          }
        end

      end
    end

    describe 'indexes groups' do
      let(:inst_id) { subject.institution.id }
      describe '#identifier_is_unique' do
        it 'should validate uniqueness of the identifier' do
          one = FactoryGirl.create(:intellectual_object, identifier: 'test.edu/234')
          two = FactoryGirl.build(:intellectual_object, identifier: 'test.edu/234')
          two.should_not be_valid
          two.errors[:identifier].should include('has already been taken')
        end
      end
    end
  end
end
