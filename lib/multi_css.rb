require "multi_css/version"

module MultiCss
  class ParseError < StandardError
    def initialize(message="", backtrace=[])
      super(message)
      self.set_backtrace(backtrace)
    end
  end

  @adapter = nil
  
  REQUIREMENT_MAP = [
    ["css_press", :css_press],
    ["cssminify", :cssminify],
    ["yuicssmin", :yuicssmin],
    ["yui/compressor", :yui_compressor],
    ["rainpress", :rainpress]
  ]

  class << self

    # The default adapter based on what you currently
    # have loaded and installed. First checks to see
    # if any adapters are already loaded, then checks
    # to see which are installed if none are loaded.
    def default_adapter
      return :css_press if defined?(::CssPress)
      return :cssminify if defined?(::CSSminify)      
      return :yuicssmin if defined?(::Yuicssmin)
      return :yui_compressor if defined?(::YUI::CssCompressor)
      return :rainpress if defined?(::Rainpress)

      REQUIREMENT_MAP.each do |(library, adapter)|
        begin
          require library
          return adapter
        rescue LoadError
          next
        end
      end

      Kernel.warn "[WARNING] MultiCss is using the default adapter."
      :vendored
    end
    # :nodoc:
    alias :default_engine :default_adapter

    # Get the current adapter class.
    def adapter
      return @adapter if @adapter
      self.use self.default_adapter
      @adapter
    end
    # :nodoc:
    alias :engine :adapter

    # Set the adapter utilizing a symbol, string, or class.
    # Supported by default are:
    #
    # * <tt>:css_press</tt>
    # * <tt>:cssminify</tt>
    # * <tt>:yuicssmin</tt>
    # * <tt>:yui_compressor</tt>
    # * <tt>:rainpress</tt>
    def use(new_adapter)
      @adapter = load_adapter(new_adapter)
    end
    alias :adapter= :use
    # :nodoc:
    alias :engine= :use

    def load_adapter(new_adapter)
      case new_adapter
      when String, Symbol
        require "multi_css/adapters/#{new_adapter}"
        self::Adapters.const_get(:"#{new_adapter.to_s.split('_').map{|s| s.capitalize}.join('')}")
      when NilClass, FalseClass
        default_adapter = self.default_adapter
        require "multi_css/adapters/#{default_adapter}"
        self::Adapters.const_get(:"#{default_adapter.to_s.split('_').map{|s| s.capitalize}.join('')}")
      when Class
        new_adapter
      else
        raise "Did not recognize your adapter specification. Please specify either a symbol or a class."
      end
    end

    def current_adapter(options)
      if new_adapter = (options || {}).delete(:adapter)
        load_adapter(new_adapter)
      else
        adapter
      end
    end

    # Minify CSS
    def min(string, options={})
      adapter = current_adapter(options)
      if defined?(adapter::ParseError)
        begin
          adapter.min(string, options)
        rescue adapter::ParseError => exception
          raise ::MultiCss::ParseError.new(exception.message, exception.backtrace)
        end
      else
        adapter.min(string, options)
      end
    end
  end

end