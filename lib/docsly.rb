require 'docsly/version'

module Docsly 
  class Parser
    attr_accessor :blocks

    def initialize(base_path)
      @blocks = []
      Dir["#{base_path}/**/*.*"].each do |filename|
        File.open filename do |file|
          current_block = nil
          inside_single_line_block = false
          file.each_line do |line|
            if !!(line =~ /^\s*#/)
              parsed = line.to_s.sub(/\s*#/, '').rstrip
              if inside_single_line_block
                current_block += "\n#{parsed}"
              else
                current_block = parsed.to_s
                inside_single_line_block = true
              end
            else
              unless current_block.nil?
                parsed = line.to_s.sub(/\s*#/, '').rstrip
                current_block += "\n#{parsed}"
                # current_block = "#{IO.readlines(filename)[0].gsub(' =', '')}\n#{current_block}"
                @blocks << current_block
              end
              current_block = nil
              inside_single_line_block = false
            end
          end
        end
        
        @blocks = @blocks.collect do |string|
          if string.is_a?(String)
            array = string.split(/\n/).delete_if{|s| s.blank? }
            # Validate that this is actually a documentation block by checking
            # for a HTTP verb in the last line.
            if !!array[-2][/GET|PUT|POST|PATCH|DELETE/]
              Docsly::Method.new(array)
            end
          else
            string
          end
        end

        @blocks.compact!
      end
    end
  end
  
  class Method
    attr_accessor :name, :description, :arguments, :example_responses, :error_codes, :verb, :url
    
    def initialize(array)
      @arguments, @example_responses, @error_codes = [], [], []
      @name = "#{array[-1][/[^=]+/].strip}"
      @description = array.delete_at(0)

      response_index = array.index{|s| s[/Example Response/] }

      if response_index > 0
        array[0..response_index-1].each{|s| add_argument(s)  }
      end

      error_index = array.index{|s| s[/Error Codes/] }

      if error_index > 0
        current_block = nil
        array[response_index..error_index-1].each do |line|
          if line =~ /Example Response/
            current_block = line.to_s.sub(/Example Response:/, '').rstrip
          elsif line == array[error_index-1]
            current_block += "\n#{line}"
            add_example_response(current_block)
          else
            current_block += "\n#{line}"
          end
        end
      end

      array[error_index+1..-3].each{|s| add_error_code(s) }

      @verb = array[-2][/[^ ]+/]
      @url = array[-2][/[^ ]+$/]
    end
    
    def add_argument(string)
      name = string[/[^-]+/].strip
      description = string[/[^-]+$/].strip
      required = string.index('(default:') ? false : true
      if !required
        default = string[/\(default:([^\)]+)/, 1].strip
        description.gsub!(/ \(default:[^.]+/, '')
      end
      @arguments << Docsly::MethodArgument.new(name, required, description, default || "")
    end
    
    def add_example_response(string)
      array = string.split("\n")
      name = array[0]
      example = array[1..-1].join("\n")
      @example_responses << Docsly::MethodExampleResponse.new(name, example)
    end
    
    def add_error_code(string)
      id = string[/[^:]+/].strip
      name = string[/[^-]+/].gsub("#{id}:", '').strip
      description = string[/[^-]+$/].strip
      @error_codes << Docsly::MethodErrorCode.new(id, name, description)
    end
  end
  
  class MethodArgument
    attr_accessor :name, :required, :description, :default
    
    def initialize(name, required, description, default)
      @name = name
      @required = required
      @description = description
      @default = default
    end
  end
  
  class MethodExampleResponse
    attr_accessor :name, :example
    
    def initialize(name, example)
      @name = name
      @example = example
    end
  end
  
  class MethodErrorCode
    attr_accessor :id, :name, :description
    
    def initialize(id, name, description)
      @id = id
      @name = name
      @description = description
    end
  end
end
