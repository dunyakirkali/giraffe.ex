defmodule Giraffe.Graph.BaseTest do
  use ExUnit.Case, async: true

  # Test helper module that implements Graph.Base
  defmodule TestGraph do
    use Giraffe.Graph.Base

    # Implement a simple add_edge for testing
    def add_edge(graph, v1, v2, weight \\ 1) do
      graph = add_vertex(graph, v1)
      graph = add_vertex(graph, v2)

      %{
        graph
        | edges: Map.put(graph.edges, v1, Map.put(Map.get(graph.edges, v1, %{}), v2, weight))
      }
    end

    def edges(graph) do
      graph.edges
      |> Enum.flat_map(fn {from, edges} ->
        Enum.map(edges, fn {to, weight} -> {from, to, weight} end)
      end)
    end

    def neighbors(graph, vertex) do
      graph.edges
      |> Map.get(vertex, %{})
      |> Map.keys()
      |> Enum.sort()
    end
  end

  describe "new/0" do
    test "creates an empty graph" do
      graph = TestGraph.new()
      assert graph.vertices == MapSet.new()
      assert graph.edges == %{}
      assert graph.labels == %{}
    end
  end

  describe "add_vertex/2" do
    test "adds a vertex without a label" do
      graph = TestGraph.new()
      graph = TestGraph.add_vertex(graph, :a)

      assert MapSet.member?(graph.vertices, :a)
      assert map_size(graph.labels) == 0
    end

    test "adds a vertex with a label" do
      graph = TestGraph.new()
      graph = TestGraph.add_vertex(graph, :a, "Label A")

      assert MapSet.member?(graph.vertices, :a)
      assert graph.labels[:a] == "Label A"
    end

    test "adding the same vertex twice doesn't create duplicates" do
      graph = TestGraph.new()
      graph = TestGraph.add_vertex(graph, :a)
      graph = TestGraph.add_vertex(graph, :a)

      assert MapSet.size(graph.vertices) == 1
    end
  end

  describe "get_label/2" do
    test "returns the label for a vertex" do
      graph = TestGraph.new()
      graph = TestGraph.add_vertex(graph, :a, "Label A")

      assert TestGraph.get_label(graph, :a) == "Label A"
    end

    test "returns nil for vertex without label" do
      graph = TestGraph.new()
      graph = TestGraph.add_vertex(graph, :a)

      assert TestGraph.get_label(graph, :a) == nil
    end

    test "returns nil for non-existent vertex" do
      graph = TestGraph.new()

      assert TestGraph.get_label(graph, :a) == nil
    end
  end

  describe "set_label/3" do
    test "sets label for existing vertex" do
      graph = TestGraph.new()
      graph = TestGraph.add_vertex(graph, :a)
      graph = TestGraph.set_label(graph, :a, "New Label")

      assert TestGraph.get_label(graph, :a) == "New Label"
    end

    test "doesn't set label for non-existent vertex" do
      graph = TestGraph.new()
      graph = TestGraph.set_label(graph, :a, "New Label")

      assert TestGraph.get_label(graph, :a) == nil
    end

    test "updates existing label" do
      graph = TestGraph.new()
      graph = TestGraph.add_vertex(graph, :a, "Old Label")
      graph = TestGraph.set_label(graph, :a, "New Label")

      assert TestGraph.get_label(graph, :a) == "New Label"
    end
  end

  describe "vertices/1" do
    test "returns empty list for empty graph" do
      graph = TestGraph.new()
      assert TestGraph.vertices(graph) == []
    end

    test "returns list of vertices" do
      graph = TestGraph.new()
      graph = TestGraph.add_vertex(graph, :a)
      graph = TestGraph.add_vertex(graph, :b)

      vertices = TestGraph.vertices(graph)
      assert length(vertices) == 2
      assert :a in vertices
      assert :b in vertices
    end
  end

  describe "reachable/2" do
    test "returns empty list for empty graph" do
      graph = TestGraph.new()
      assert TestGraph.reachable(graph, [:a]) == []
    end

    test "returns single vertex when no edges exist" do
      graph = TestGraph.new()
      graph = TestGraph.add_vertex(graph, :a)

      assert TestGraph.reachable(graph, [:a]) == [:a]
    end

    test "returns connected vertices" do
      graph =
        TestGraph.new()
        |> TestGraph.add_edge(:a, :b)
        |> TestGraph.add_edge(:b, :c)
        |> TestGraph.add_edge(:c, :d)

      reachable = TestGraph.reachable(graph, [:a])
      assert length(reachable) == 4
      assert Enum.sort(reachable) == [:a, :b, :c, :d]
    end

    test "handles disconnected components" do
      graph =
        TestGraph.new()
        |> TestGraph.add_edge(:a, :b)
        |> TestGraph.add_edge(:c, :d)

      assert Enum.sort(TestGraph.reachable(graph, [:a])) == [:a, :b]
      assert Enum.sort(TestGraph.reachable(graph, [:c])) == [:c, :d]
    end

    test "handles multiple starting vertices" do
      graph =
        TestGraph.new()
        |> TestGraph.add_edge(:a, :b)
        |> TestGraph.add_edge(:c, :d)

      assert Enum.sort(TestGraph.reachable(graph, [:a, :c])) == [:a, :b, :c, :d]
    end
  end

  describe "postorder/1" do
    test "returns empty list for empty graph" do
      graph = TestGraph.new()
      assert TestGraph.postorder(graph) == []
    end

    test "returns single vertex for isolated vertex" do
      graph = TestGraph.new()
      graph = TestGraph.add_vertex(graph, :a)

      assert TestGraph.postorder(graph) == [:a]
    end

    test "returns vertices in post-order for linear path" do
      graph =
        TestGraph.new()
        |> TestGraph.add_edge(:a, :b)
        |> TestGraph.add_edge(:b, :c)
        |> TestGraph.add_edge(:c, :d)

      assert TestGraph.postorder(graph) == [:d, :c, :b, :a]
    end

    test "handles branching paths" do
      graph =
        TestGraph.new()
        |> TestGraph.add_edge(:a, :b)
        |> TestGraph.add_edge(:a, :c)
        |> TestGraph.add_edge(:b, :d)
        |> TestGraph.add_edge(:c, :e)

      result = TestGraph.postorder(graph)
      assert length(result) == 5
      # Check that parent vertices come after their children
      assert_parent_after_children(result)
    end
  end

  # Helper function to verify post-order property
  defp assert_parent_after_children(vertices) do
    vertices_indexed = Enum.with_index(vertices) |> Map.new()

    for vertex <- vertices do
      parent_index = Map.get(vertices_indexed, vertex)

      # Check that all children appear before their parent
      children_indices = get_children_indices(vertex, vertices_indexed)

      for child_index <- children_indices do
        assert child_index < parent_index,
               "Child #{vertex} appears after parent at index #{parent_index}"
      end
    end
  end

  defp get_children_indices(vertex, vertices_indexed) do
    case vertex do
      :a -> [Map.get(vertices_indexed, :b), Map.get(vertices_indexed, :c)]
      :b -> [Map.get(vertices_indexed, :d)]
      :c -> [Map.get(vertices_indexed, :e)]
      _ -> []
    end
    |> Enum.filter(&(&1 != nil))
  end
end
