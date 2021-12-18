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

  def initialize resource, opts = SymMash.new
    super
    @document = self.class.service.get_document resource
  end

  def next_text last_text
    return unless paras = lookup_and_parse(last_text)

    original = select(paras.original)
    require'pry';binding.pry
    SymMash.new(
      last:     paras.last,
      original: original,
      final:    paras.final.first(original.size),
    )
  end

  protected

  def lookup_and_parse last_text
    tables = @document.body.content.map{ |c| c.table }.compact
    tables.each do |t|
      t.table_rows.each_cons 6 do |r, *nexts|
        next unless cells_find(r.table_cells, last_text)

        last = parse_content(r.table_cells.first) + parse_content(r.table_cells.second)
        return SymMash.new(
          last:     last,
          original: nexts.flat_map{ |a| parse_content a.table_cells.first },
          final:    nexts.flat_map{ |a| parse_content a.table_cells.second },
        )
      end
    end
    nil
  end

  ##
  # Return the index of the paragraph found in `content`
  #
  def cells_find cells, last_text
    cells.each do |cell|
      content = parse_content(cell).join
      return true if content.index last_text
    end
    false
  end

  def parse_content el
    paras = el.content.flat_map{ |c| c.paragraph }
    paras.map! do |p|
      p.elements.map{ |e| e.text_run&.content&.strip }.join
    end
    paras.reject!{ |p| p.blank? }
    paras
  end

end
