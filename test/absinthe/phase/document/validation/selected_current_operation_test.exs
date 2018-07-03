defmodule Absinthe.Phase.Document.Validation.SelectedCurrentOperationTest do
  @phase Absinthe.Phase.Document.Validation.SelectedCurrentOperation

  use Absinthe.ValidationPhaseCase,
    phase: @phase,
    async: true

  alias Absinthe.Blueprint

  defp no_current_operation do
    bad_value(
      Blueprint,
      @phase.error_message,
      nil
    )
  end

  describe "Given an operation name" do
    test "passes when the operation is provided" do
      assert_passes_validation(
        """
        query Bar {
          name
        }
        query Foo {
          name
        }
        """,
        operation_name: "Foo"
      )
    end

    test "fails when the operation is not provided" do
      assert_fails_validation(
        """
        query Bar {
          name
        }
        query Foo {
          name
        }
        """,
        [operation_name: "Nothere"],
        no_current_operation()
      )
    end
  end

  describe "Not given an operation name" do
    test "passes when only one operation is given and is named" do
      assert_passes_validation(
        """
        query Bar {
          name
        }
        """,
        []
      )
    end

    test "passes when only one operation is given anonymously" do
      assert_passes_validation(
        """
        {
          name
        }
        """,
        []
      )
    end

    test "fails when more that one operation is given" do
      assert_fails_validation(
        """
        query Bar {
          name
        }
        query Foo {
          name
        }
        """,
        [],
        no_current_operation()
      )
    end
  end
end
