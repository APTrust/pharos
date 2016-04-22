require 'spec_helper'

describe PremisEventsHelper do

  let(:id) { '123' }
  let(:uri) { 'uri for file' }
  let(:identifier) { 'test.edu/1234567' }

  describe '#generic_file_link' do
    it 'returns a link for the GenericFile' do
      solr_doc = { 'generic_file_id_ssim' => [id],
                   'generic_file_identifier_ssim' => [identifier]}
      expected_result =  "<a href=\"/files/#{identifier}\">#{identifier}</a>"
      helper.generic_file_link(solr_doc).should == expected_result
    end
  end

  describe '#intellectual_object_link' do
    it 'returns a link for the IntellectualObject' do
      solr_doc = { 'intellectual_object_id_ssim' => [id],
                   'intellectual_object_identifier_ssim' => [identifier]}
      expected_result =  "<a href=\"/objects/#{identifier}\">#{identifier}</a>"
      helper.intellectual_object_link(solr_doc).should == expected_result
    end
  end

  describe '#parent_object_link' do

    describe 'without enough info in the solr doc' do
      it 'it returns a string instead of a link' do
        helper.parent_object_link({}).should == 'Event'
      end
    end

    describe 'with info about a generic file' do
      let(:solr_doc) { { 'generic_file_id_ssim' => [id],
                         'generic_file_uri_ssim' => [uri] }
      }

      it 'returns a link to the generic file' do
        helper.should_receive(:generic_file_link).with(solr_doc)
        helper.parent_object_link(solr_doc)
      end
    end

    describe 'with info about an intellectual object' do
      let(:solr_doc) { { 'intellectual_object_id_ssim' => [id] } }
      it 'returns a link to the intellectual object' do
        helper.should_receive(:intellectual_object_link).with(solr_doc)
        helper.parent_object_link(solr_doc)
      end
    end

  end

  describe '#dislay_event_outcome' do
    describe 'without enough info in the solr doc' do
      it 'returns nil' do
        helper.display_event_outcome({}).should == nil
      end
    end

    describe 'when the outcome is a node' do
      let(:solr_doc) { { 'event_outcome_ssim' => ['success'] } }

      it 'returns the first entry' do
        helper.display_event_outcome(solr_doc).should == 'success'
      end
    end

    describe 'when the outcome is a string' do
      let(:solr_doc) { { 'event_outcome_ssim' => 'success' } }

      it 'returns the string' do
        helper.display_event_outcome(solr_doc).should == 'success'
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