defmodule Giraffe.Graph.Base do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      defstruct vertices: MapSet.new(), edges: %{}, labels: %{}

      @type vertex :: any()
      @type weight :: number()
      @type edge :: {vertex(), vertex(), weight()}
      @type t :: %__MODULE__{
              vertices: MapSet.t(),
              edges: %{vertex() => %{vertex() => weight()}},
              labels: map()
            }

      @doc """
      Creates a new empty graph.

      ## Examples

          iex> Giraffe.Graph.Directed.new()
          %Giraffe.Graph.Directed{vertices: MapSet.new(), edges: %{}, labels: %{}}
      """
      @spec new() :: t()
      def new, do: %__MODULE__{}

      @doc """
      Adds a vertex to the graph with an optional label.

      ## Examples

          iex> graph = Giraffe.Graph.Directed.new()
          iex> Giraffe.Graph.Directed.add_vertex(graph, :a, "vertex A")
          %Giraffe.Graph.Directed{vertices: MapSet.new([:a]), edges: %{}, labels: %{a: "vertex A"}}
      """
      @spec add_vertex(t(), vertex(), label :: any()) :: t()
      def add_vertex(graph, vertex, label \\ nil) do
        %{
          graph
          | vertices: MapSet.put(graph.vertices, vertex),
            labels: if(label, do: Map.put(graph.labels, vertex, label), else: graph.labels)
        }
      end

      @doc """
      Gets the label associated with a vertex.

      ## Examples

          iex> graph = Giraffe.Graph.Directed.new() |> Giraffe.Graph.Directed.add_vertex(:a, "vertex A")
          iex> Giraffe.Graph.Directed.get_label(graph, :a)
          "vertex A"
      """
      @spec get_label(t(), vertex()) :: any() | nil
      def get_label(graph, vertex) do
        Map.get(graph.labels, vertex)
      end

      @doc """
      Sets a label for an existing vertex.
      Returns unchanged graph if vertex doesn't exist.

      ## Examples

          iex> graph = Giraffe.Graph.Directed.new() |> Giraffe.Graph.Directed.add_vertex(:a)
          iex> Giraffe.Graph.Directed.set_label(graph, :a, "new label")
          %Giraffe.Graph.Directed{vertices: MapSet.new([:a]), edges: %{}, labels: %{a: "new label"}}
      """
      @spec set_label(t(), vertex(), label :: any()) :: t()
      def set_label(graph, vertex, label) do
        if MapSet.member?(graph.vertices, vertex) do
          %{graph | labels: Map.put(graph.labels, vertex, label)}
        else
          graph
        end
      end

      @doc """
      Returns a list of all vertices in the graph.

      ## Examples

          iex> graph = Giraffe.Graph.Directed.new() |> Giraffe.Graph.Directed.add_vertex(:a)
          iex> Giraffe.Graph.Directed.vertices(graph)
          [:a]
      """
      @spec vertices(t()) :: [vertex()]
      def vertices(%__MODULE__{vertices: vertices}), do: MapSet.to_list(vertices)

      @doc """
      Returns a list of all vertices reachable from the given starting vertices.

      ## Examples

          iex> graph = Giraffe.Graph.Directed.new()
          ...> |> Giraffe.Graph.Directed.add_edge(:a, :b, 1)
          ...> |> Giraffe.Graph.Directed.add_edge(:b, :c, 1)
          iex> Giraffe.Graph.Directed.reachable(graph, [:a])
          [:a, :b, :c]
      """
      @spec reachable(t(), [vertex()]) :: [vertex()]
      def reachable(graph, vertices) do
        vertices
        |> Enum.reduce(MapSet.new(), fn vertex, acc ->
          if MapSet.member?(graph.vertices, vertex) do
            do_reachable(graph, vertex, MapSet.new(), acc)
          else
            acc
          end
        end)
        |> MapSet.to_list()
      end

      defp do_reachable(graph, vertex, visited, acc) do
        if MapSet.member?(visited, vertex) do
          acc
        else
          visited = MapSet.put(visited, vertex)
          acc = MapSet.put(acc, vertex)

          neighbors(graph, vertex)
          |> Enum.reduce(acc, fn neighbor, new_acc ->
            if MapSet.member?(graph.vertices, neighbor) do
              do_reachable(graph, neighbor, visited, new_acc)
            else
              new_acc
            end
          end)
        end
      end

      @doc """
      Returns vertices in post-order DFS traversal order.

      ## Examples

          iex> graph = Giraffe.Graph.Directed.new()
          ...> |> Giraffe.Graph.Directed.add_edge(:a, :b, 1)
          ...> |> Giraffe.Graph.Directed.add_edge(:b, :c, 1)
          iex> Giraffe.Graph.Directed.postorder(graph)
          [:c, :b, :a]
      """
      @spec postorder(t()) :: [vertex()]
      def postorder(%__MODULE__{vertices: vertices, edges: edges}) do
        visited = MapSet.new()
        result = []

        vertices
        |> MapSet.to_list()
        |> Enum.reduce({visited, result}, fn vertex, {visited, result} ->
          if MapSet.member?(visited, vertex) do
            {visited, result}
          else
            dfs_postorder(vertex, edges, visited, result)
          end
        end)
        |> elem(1)
        |> Enum.reverse()
      end

      @spec dfs_postorder(vertex(), map(), MapSet.t(), [vertex()]) :: {MapSet.t(), [vertex()]}
      defp dfs_postorder(vertex, edges, visited, result) do
        visited = MapSet.put(visited, vertex)

        {new_visited, new_result} =
          edges
          |> Map.get(vertex, %{})
          |> Map.keys()
          |> Enum.reduce({visited, result}, fn neighbor, {vis, res} ->
            if MapSet.member?(vis, neighbor) do
              {vis, res}
            else
              dfs_postorder(neighbor, edges, vis, res)
            end
          end)

        {new_visited, [vertex | new_result]}
      end

      # Allow modules using this to override these functions
      defoverridable new: 0, add_vertex: 3, vertices: 1
    end
  end
end
