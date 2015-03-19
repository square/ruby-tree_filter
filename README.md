# Tree Filter

Filter arbitrary data trees with a concise query language. Similar to how the
Jenkins API works, if you happen to be familiar with that.

    name,environments             # Select specific attributes from a hash
    environments[id,last_deploy]  # Select attributes from sub-hash
    environments[*]               # Select all attributes

## Usage

```ruby
require 'tree_filter'

data = {
  'name' => 'don',
  'contact' => {
    'phone' => '415-123-4567',
    'email' => 'don@example.com'
  }
}

TreeFilter.new("name,contact[email]").filter(data)
# => {'name' => 'don', 'contact' => {'email' => 'don@example.com'}}
```

Different data structures can be presented dependent on whether they are
explicitly expanded or not. This is typically used when referring to other
resources in an API response.

```ruby
data = {
  'name' => 'don',
  'contact' => TreeFilter::Leaf.new('/contact-data/1', {
    'phone' => '415-123-4567',
    'email' => 'don@example.com'
  })
}

TreeFilter.new("*").filter(data)
# => {'name' => 'don', 'contact' => '/contact-data/1'}

TreeFilter.new("contact[*]").filter(data)
# => {'contact' => {'phone' => '415-123-4567', 'email' => 'don@example.com'}}
```

For nested data structures, evaluation can be defered until it is actually
required. This can defer resource lookups, and also allows cyclic structures!

```ruby
data = { 'name' => 'don', }

data['contact'] = TreeFilter::Leaf.new(
    '/contact-data/1',
    TreeFilter::Defer.new(->{{
      'email' => 'don@example.com',
      'person' => TreeFilter::Leaf.new('/person/1', data)
    }})
  )
}

TreeFilter.new("contact[person[contact[email]]]").filter(data)
# => {'contact' => {'person' => {'contact' => {'email' => 'don@example.com'}}}}
```

## Compatibility

All rubies that ruby core supports! Should work on JRuby and Rubinius too.

## Support

Make a [new github
issue](https://github.com/square/ruby-tree_filter/issues/new).

## Contributing

Fork and patch! Before any changes are merged to master, we need you to sign an
[Individual Contributor
Agreement](https://spreadsheets.google.com/a/squareup.com/spreadsheet/viewform?formkey=dDViT2xzUHAwRkI3X3k5Z0lQM091OGc6MQ&ndplr=1)
(Google Form).

Run tests:

    gem install bundler
    bundle
    bundle exec rspec
