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

  attr_reader :document

  def initialize resource
    super
    @document = self.class.service.get_document resource
  end

  def next_text last_text
    return unless paras = lookup_and_parse(last_text)

    report_last paras.original.first + paras.final.first

    SymMash.new(
      original: select(paras.original[1..-1]),
      final:    select(paras.final[1..-1]),
    )
  end

  protected

  def lookup_and_parse last_text
    tables = @document.body.content.map{ |c| c.table }.compact
    tables.each do |t|
      t.table_rows.each_cons 6 do |r, *others|
        content = r.table_cells.flat_map(&:content)
        next unless content_find content, last_text

        all = [r] + others
        return SymMash.new(
          original: all.flat_map{ |a| parse_cell a.table_cells.first },
          final:    all.flat_map{ |a| parse_cell a.table_cells.second },
        )
      end
    end
    nil
  end

  def parse_cell cl
    paras = cl.content.flat_map do |c|
      c.paragraph.elements.flat_map do |e|
        e.text_run.content.strip
      end
    end
    paras.reject!{ |p| p.blank? }
    paras
  end

  def content_find content, last_text
    content.each do |c|
      c.paragraph.elements.each do |e|
        return true if e.text_run.content.index last_text
      end
    end
    false
  end

end
