require File.expand_path('../../../../vendor/cssminify/lib/cssminify', __FILE__)
require 'cssminify'

module MultiCss
  module Adapters
    class Vendored < Cssminify
    end
  end
end
