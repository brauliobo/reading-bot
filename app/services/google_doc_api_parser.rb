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

    SymMash.new(
      last:     paras.last,
      original: select(paras.original),
      final:    select(paras.final),
    )
  end

  protected

  def lookup_and_parse last_text
    tables = @document.body.content.map{ |c| c.table }.compact
    tables.each do |t|
      t.table_rows.each_cons 6 do |r, *nexts|
        content = r.table_cells.map(&:content)
        next unless i = content_find(content, last_text)

        last = parse_cell(r.table_cells.first) + parse_cell(r.table_cells.second)
        return SymMash.new(
          last:     last,
          original: nexts.flat_map{ |a| parse_cell a.table_cells.first },
          final:    nexts.flat_map{ |a| parse_cell a.table_cells.second },
        )
      end
    end
    nil
  end

  def parse_cell cl, i = 0
    elements = cl.content.flat_map{ |c| c.paragraph.elements }
    elements = elements[i..-1]

    paras = elements.map do |e|
      e.text_run.content.strip
    end
    paras.reject!{ |p| p.blank? }
    paras
  end

  ##
  # Return the index of the paragraph found in `content`
  #
  def content_find cells_content, last_text
    cells_content.each do |content|
      elements = content.flat_map{ |c| c.paragraph.elements }
      elements.each.with_index do |e, i|
        next unless e.text_run
        return i if e.text_run.content.index last_text
      end
    end
    false
  end

end
