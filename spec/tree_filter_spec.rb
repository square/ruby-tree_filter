require 'json'

require 'tree_filter'

describe 'Tree filter spec:' do
  def filter(data, input)
    TreeFilter.new(input).filter(data)
  end

  describe 'filtering a hash' do
    it 'only includes specified attributes' do
      data = {'a' => 1, 'b' => 2, 'c' => 3}

      expect(filter(data, 'a,b')).to eq('a' => 1, 'b' => 2)
    end

    it 'can include sub-tree attributes' do
      data = {'a' => {'c' => 3, 'd' => 4}, 'b' => 2}

      expect(filter(data, 'a[c]')).to eq('a' => {'c' => 3})
    end

    it 'can traverse arbitrary depth' do
      data = {'a' => {'b' => {'c' => 1, 'd' => 2}, 'e' => 3, 'f' => 4}}

      expect(filter(data, 'a[b[c],e]')).to \
        eq('a' => {'b' => {'c' => 1}, 'e' => 3})
    end

    it 'includes nil values' do
      data = {'a' => 1, 'b' => nil, 'c' => 3}

      expect(filter(data, 'a,b')).to eq('a' => 1, 'b' => nil)
    end

    it 'can defer evaluation of lambdas' do
      data = {
        'a' => TreeFilter::Defer.new(->{ 1 }),
        'b' => TreeFilter::Defer.new(->{ raise })
      }

      expect(filter(data, 'a')).to eq('a' => 1)
    end

    it 'filters defered evaluations' do
      data = {
        'a' => TreeFilter::Defer.new(->{{'b' => 1, 'c' => 2}}),
      }

      expect(filter(data, 'a[b]')).to eq('a' => {'b' => 1})
    end

    it 'allows cyclic references with defer' do
      data = {
        'a' => TreeFilter::Leaf.new(1, TreeFilter::Defer.new(->{ data }))
      }

      expect(filter(data, 'a[a[a]]').to_json).to \
        eq({'a' => {'a' => {'a' => 1}}}.to_json)
    end

    it 'handles null filter' do
      data = {'a' => {'c' => 3, 'd' => 4}, 'b' => 2}

      expect(filter(data, 'a[]')).to eq('a' => {})
    end

    it 'allows leaf alternation' do
      data = {'a' => TreeFilter::Leaf.new('/a', 'id' => 'a', 'name' => 'b')}

      expect(filter(data, 'a')).to eq('a' => '/a')
      expect(filter(data, 'a[id]')).to eq('a' => {'id' => 'a'})
    end

    it 'allows recursive leaf alternation' do
      data = {'a' => TreeFilter::Leaf.new('',
        'b' => TreeFilter::Leaf.new('/b', 'f')
      )}

      expect(filter(data, 'a[b]')).to eq('a' => {'b' => '/b'})
    end

    it 'allows * for all attributes' do
      data = {'a' => {'c' => 3, 'd' => 4}, 'b' => 2}

      expect(filter(data, 'a[*]')).to eq('a' => {'c' => 3, 'd' => 4})
    end

    it 'takes left tree for *' do
      data = {'a' => {'c' => TreeFilter::Leaf.new('/c', 'fail')}, 'b' => 2}

      expect(filter(data, 'a[*]')).to eq('a' => {'c' => '/c'})
    end

    it 'converts objects to JSON' do
      a = Object.new
      def a.as_json(*args)
        {'a' => 1, 'b' => 2}
      end

      data = {'a' => a}

      expect(filter(a, 'b')).to eq('b' => 2)
    end
  end

  describe 'filtering an array' do
    it 'applies filter to each element' do
      data = [{'a' => 1, 'b' => 2}, {'a' => 3, 'b' => 4}]

      expect(filter(data, 'a')).to eq([{'a' => 1}, {'a' => 3}])
    end

    it 'allows leaf alternation' do
      data = ['a' => TreeFilter::Leaf.new('/a', 'id' => 'a', 'name' => 'b')]

      expect(filter(data, 'a[id]')).to eq(['a' => {'id' => 'a'}])
    end
  end

  it 'does not try to recurse into plain values' do
      data = {'a' => 'b'}

      expect(filter(data, 'a[*]')).to eq('a' => 'b')
  end
end

