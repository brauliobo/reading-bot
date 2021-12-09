require 'hashie'

class SymMash < ::Hashie::Mash

  disable_warnings

  include Hashie::Extensions::Mash::SymbolizeKeys

  def inspect
    map do |k,v|
      v = "{#{v.inspect}}" if v.is_a? SymMash
      "#{k}: #{v}"
    end.join ' '
  end

end

