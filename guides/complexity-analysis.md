# Complexity Analysis

A misbehaving client might send a very complex GraphQL query that would require
considerable resources to handle. In order to protect against this scenario, the
complexity of a query can be estimated before it is resolved and limited to a
specified maximum.

For example, to enable complexity analysis and limit the complexity to a value
of `50` -- if we were using `Absinthe.run/3` directly -- we would do this:

```elixir
Absinthe.run(doc, MyAppWeb.Schema, analyze_complexity: true, max_complexity: 50)
```

That would translate to the following configuration when using
[absinthe_plug](https://hex.pm/packages/absinthe_plug) (>= v1.2.3):

```elixir
plug Absinthe.Plug,
  schema: MyAppWeb.Schema,
  analyze_complexity: true,
  max_complexity: 50
```

The maximum value, `50`, is compared to complexity values calculated for each request.

## Complexity Analysis

Here's how the complexity value is calculated:

By default each field in a query will increase the complexity by 1. However it
can be useful to customize how the complexity value for a field. This is done in your schema using the
`complexity/1` macro, which can accept a function or an explicit integer value.

As an example, when a field is a list, the complexity is often correlated to the
size of the list. To prevent large selections, a field can use a limit argument
with a suitable default (think, for instance, of page sizes during pagination),
and complexity can be calculated keeping that in mind. Here is a schema that
supports analyzing (and limiting) complexity using that approach:

```elixir
defmodule MyAppWeb.Schema do

  use Absinthe.Schema

  query do
    field :people, list_of(:person) do
      arg :limit, :integer, default_value: 10
      complexity fn %{limit: limit}, child_complexity ->
        # set complexity based on maximum number of items in the list and
        # complexity of a child.
        limit * child_complexity
      end
    end
  end

  object :person do
    field :name, :string
    field :age, :integer
    # constant complexity for this object
    complexity 3
  end

end
```

For a field, the first argument to the function you supply to `complexity/1` is the user arguments
-- just as a field's resolver can use user arguments to resolve its value, the complexity
function that you provide can use the same arguments to calculate the field's complexity.

The second argument passed to your complexity function is the child (that is,
the result of the field); in the example above, `child_complexity` would be `3`,
as the field returns a list of `:person` objects, and the complexity of
`:person` is explicitly set to `3`.

(If a complexity function accepts three arguments, the third will be an
`%Absinthe.Resolution{}` struct, just as with resolvers.)

If the value of a document's `:limit` argument was `10`, the complexity of a single
`:people` field would be calculated as `30`; `10`, the value of `:limit`, times `3`, the complexity of
the `:person` type.

So this would be okay:

```graphql
{
  people(limit: 10) {
    name
  }
}
```

But this, at a complexity of `60`, wouldn't:

```graphql
{
  people(limit: 20) {
    name
  }
}
```

### Complexity limiting

If a document's calculated complexity exceeds the configured limit, resolution
will be skipped and an error will be returned in the result detailing the
calculated and maximum complexities.
