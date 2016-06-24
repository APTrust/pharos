require 'spec_helper'

describe PremisEventsHelper do

  let(:id) { '123' }
  let(:uri) { 'uri for file' }
  let(:identifier) { 'test.edu/1234567' }
  let(:event) { FactoryGirl.create(:premis_event_fixity_check) }
  let(:file) { FactoryGirl.create(:generic_file) }
  let(:object) { FactoryGirl.create(:intellectual_object) }

  describe '#generic_file_link' do
    it 'returns a link for the GenericFile' do
      event.generic_file = file
      esc = file.identifier.gsub('/', '%2F')
      expected_result =  "<a href=\"/files/#{esc}\">#{file.identifier}</a>"
      helper.generic_file_link(event).should == expected_result
    end
  end

  describe '#intellectual_object_link' do
    it 'returns a link for the IntellectualObject' do
      event.intellectual_object = object
      esc = object.identifier.gsub('/', '%2F')
      expected_result =  "<a href=\"/objects/#{esc}\">#{object.identifier}</a>"
      helper.intellectual_object_link(event).should == expected_result
    end
  end

  describe '#parent_object_link' do

    describe 'without enough info in the solr doc' do
      it 'it returns a string instead of a link' do
        helper.parent_object_link(nil).should == 'Event'
      end
    end

    describe 'with info about a generic file' do
      it 'returns a link to the generic file' do
        event.generic_file = file
        helper.should_receive(:generic_file_link).with(event)
        helper.parent_object_link(event)
      end
    end

    describe 'with info about an intellectual object' do
      it 'returns a link to the intellectual object' do
        event.intellectual_object = object
        helper.should_receive(:intellectual_object_link).with(event)
        helper.parent_object_link(event)
      end
    end

  end

  describe '#dislay_event_outcome' do
    describe 'without enough info in the solr doc' do
      it 'returns nil' do
        helper.display_event_outcome(nil).should == nil
      end
    end

    describe 'when the outcome is a node' do
      it 'returns the first entry' do
        helper.display_event_outcome(event).should == 'success'
      end
    end

    describe 'when the outcome is a string' do
      it 'returns the string' do
        helper.display_event_outcome(event).should == 'success'
      end
    end
  end

  describe '#event_catalog_title' do
    it 'includes institution name if viewing institution events' do
      inst = FactoryGirl.build(:institution)
      assign(:institution, inst)
      helper.event_catalog_title.should == "Events for #{inst.name}"
    end

    it 'includes object title if viewing events for an object' do
      object = FactoryGirl.build(:intellectual_object)
      assign(:parent_object, object)
      helper.event_catalog_title.should == "Events for #{object.title}"
    end

    it 'has a default value to fail over to' do
      helper.event_catalog_title.should == 'Events'
    end
  end

end