require 'google/apis/docs_v1'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

class GoogleDocApiParser < BaseParser

  CREDENTIALS_PATH = 'credentials.json'.freeze
  SCOPE            = Google::Apis::DocsV1::AUTH_DOCUMENTS_READONLY
  PARAMS           = {scope: SCOPE, json_key_io: File.open(CREDENTIALS_PATH)} if File.exists? CREDENTIALS_PATH

  def self.authorizer
    @authorizer ||= Google::Auth::ServiceAccountCredentials.make_creds(PARAMS).tap do |a|
      a.fetch_access_token!
    end
  end
  def self.service
    @service ||= Google::Apis::DocsV1::DocsService.new.tap do |s|
      s.authorization = authorizer
    end
  end
  def self.load
    service
  end

  attr_reader :document

  def initialize subscriber, opts = SymMash.new
    super
  end

  def document
    @document ||= self.class.service.get_document resource
  end

  def updated_content
    tables = document.body.content.map{ |c| c.table }.compact
    tables.flat_map do |t|
      t.table_rows.map do |r|
        SymMash.new(
          original: parse_content(r.table_cells.first),
          final:    parse_content(r.table_cells.second),
        )
      end
    end
  end

  protected

  def parse_content el
    paras = el.content.flat_map{ |c| c.paragraph }
    paras.map! do |p|
      p.elements.map{ |e| e.text_run&.content&.strip }.join
    end
    paras.reject!{ |p| p.blank? }
    paras
  end

end
