defmodule Mix.Tasks.Absinthe.Schema.SdlTest do
  use Absinthe.Case, async: true

  alias Mix.Tasks.Absinthe.Schema.Sdl, as: Task

  defmodule TestSchema do
    use Absinthe.Schema

    """
    schema {
      query: Query
    }

    type Query {
      helloWorld(name: String!): String
    }
    """
    |> import_sdl
  end

  @test_schema "Mix.Tasks.Absinthe.Schema.SdlTest.TestSchema"

  defmodule TestModField do
    use Absinthe.Schema.Notation

    object :test_mod_helper do
      description "Simple Helper Object used to define blueprint fields"

      field :mod_field, :string do
        description "extra field added by schema modification"
      end
    end
  end

  defmodule TestModifier do
    alias Absinthe.{Phase, Pipeline, Blueprint}

    # Add this module to the pipeline of phases
    # to run on the schema
    def pipeline(pipeline) do
      Pipeline.insert_after(pipeline, Phase.Schema.TypeImports, __MODULE__)
    end

    # Here's the blueprint of the schema, let's do whatever we want with it.
    def run(blueprint = %Blueprint{}, _) do
      test_mod_types = Blueprint.types_by_name(TestModField)
      test_mod_fields = test_mod_types["TestModHelper"]

      mod_field = Blueprint.find_field(test_mod_fields, "mod_field")

      blueprint = Blueprint.add_field(blueprint, "Mod", mod_field)

      {:ok, blueprint}
    end
  end

  defmodule TestSchemaWithMods do
    use Absinthe.Schema

    @pipeline_modifier TestModifier

    query do
      field :hello_world, :mod do
        arg :name, non_null(:string)
      end
    end

    object :mod do
    end
  end

  @test_mod_schema "Mix.Tasks.Absinthe.Schema.SdlTest.TestSchemaWithMods"

  describe "absinthe.schema.sdl" do
    test "parses options" do
      argv = ["output.graphql", "--schema", @test_schema]

      opts = Task.parse_options(argv)

      assert opts.filename == "output.graphql"
      assert opts.schema == TestSchema
    end

    test "provides default options" do
      argv = ["--schema", @test_schema]

      opts = Task.parse_options(argv)

      assert opts.filename == "./schema.graphql"
      assert opts.schema == TestSchema
    end

    test "fails if no schema arg is provided" do
      argv = []
      catch_error(Task.parse_options(argv))
    end

    test "Generate schema" do
      argv = ["--schema", @test_schema]
      opts = Task.parse_options(argv)

      {:ok, schema} = Task.generate_schema(opts)
      assert schema =~ "helloWorld(name: String!): String"
    end

    test "Generate schema with modifier" do
      argv = ["--schema", @test_mod_schema]
      opts = Task.parse_options(argv)

      {:ok, schema} = Task.generate_schema(opts)

      assert schema =~ "type Mod {"
      assert schema =~ "modField: String"
    end
  end
end
