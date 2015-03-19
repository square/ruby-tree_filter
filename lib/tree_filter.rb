require 'stringio'

# Allows filtering of complex data-structure using a string query language.
#
# Query examples:
#
#     name,environments             # Select specific attributes from a hash
#     environments[id,last_deploy]  # Select attributes from sub-hash
#     environments[*]               # Select all attributes
#
# Two special objects are provided for richer data structure evaluation, Leaf
# and Defer. See their documentation respectively.
#
# More examples in unit specs.
class TreeFilter
  def initialize(input)
    @input = StringIO.new(input)
  end

  def filter(value)
    slice.filter(value)
  end

  module JsonTerminal
    # This breaks the contract of `to_json`, since only terminal classes
    # (hard-coded into activesupport) should return themselves. We need to use
    # `as_json` to expand other classes, however. Data structures containing
    # this object should always be filtered before being converted though, so
    # in practice this shouldn't be an issue.
    def as_json(*args)
      self
    end
  end

  # Allows different data structures to be presented dependent on whether it is
  # explicitly selected or not. Usually used to provide a "summary" object by
  # default, and then only include detail if explicitly asked for.
  #
  #     data = {'a' => TreeFilter::Leaf.new('/a', {'id' => 'a'})}
  #
  #     TreeFilter.new("env").filter(data)    # => {'env' => '/a'}
  #     TreeFilter.new("env[*]").filter(data) # => {'env' => {'id' => 'a'}}
  #
  # @note All data structures containing this object must be filtered before
  # converting to JSON, otherwise you will get a stack overflow error.
  Leaf = Struct.new(:left, :right) do
    include JsonTerminal
  end

  # The wrapped lamda will not be executed unless it is actually required in
  # the filtered response. This can be used for performance optimization, and
  # also to break cycles.
  #
  #     data = {'a' => 1, 'b' => TreeFilter::Defer.new(->{ raise })}
  #
  #     TreeFilter.new("a").filter(data) # => {'a' => 1}
  #     TreeFilter.new("b").filter(data) # => raise
  #
  # @note All data structures containing this object must be filtered before
  # converting to JSON, otherwise you will get a stack overflow error.
  Defer = Struct.new(:f) do
    include JsonTerminal

    def call
      f.call
    end
  end

  def inspect
    "<TreeFilter #{slice.attrs.inspect}>"
  end
  private

  # Indicates no more filtering for the given object, return it as is.
  class NullSlice
    def filter(x)
      case x
      when Leaf
        filter(x.left)
      when Defer
        filter(x.call)
      else
        x
      end
    end
  end

  Slice = Struct.new(:attrs) do
    def inspect
      "<Slice #{@attrs.inspect}>"
    end

    def initialize(attrs = {})
      super
      @attrs = attrs
    end

    def filter(value)
      # With activesupport this will always be evaluated, because `as_json` is
      # monkey-patched on to Object.
      value = value.as_json if value.respond_to?(:as_json)

      case value
      when Hash
        slices = @attrs.dup

        if @attrs.keys.include?('*')
          slices.delete("*")
          extra = value.keys - slices.keys - ['*']
          extra.each do |k|
            slices[k] = nil
          end
        end

        slices.each_with_object({}) do |(attr, slice), ret|
          slice ||= NullSlice.new

          val = value[attr]

          filtered = case val
          when Array
            val.map {|x| slice.filter(x) }
          else
            slice.filter(val)
          end

          ret[attr] = filtered
        end
      when Array
        value.map {|x| filter(x) }
      when Defer
        filter(value.call)
      when Leaf
        filter(value.right)
      else
        value
      end
    end
  end

  def slice
    @slice ||= parse(@input)
  end

  def parse(input)
    slices = {}
    label  = ""

    while char = input.read(1)
      case char
      when ','
        unless label.empty?
          slices[label] = nil
          label = ""
        end
      when '['
        slices[label] = parse(input)
        label = ""
      when ']'
        break
      else
        label << char
      end
    end

    slices[label] = nil unless label.empty?

    return Slice.new(slices)
  end
end
