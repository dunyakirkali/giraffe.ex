defmodule Giraffe.Graph do
  @moduledoc """
  Public interface for working with graphs. Delegates to specific implementations
  based on whether the graph is directed or undirected.
  """

  defstruct [:type, :impl]

  @type vertex :: any()
  @type weight :: number()
  @type label :: any()
  @type edge :: {vertex(), vertex(), weight()}
  @type t :: %__MODULE__{
          type: :directed | :undirected,
          impl: Giraffe.Graph.Directed.t() | Giraffe.Graph.Undirected.t()
        }

  @doc """
  Creates a new graph.

  ## Options
    * `:type` - The type of graph. Can be `:directed` or `:undirected`. Defaults to `:directed`.

  ## Examples

      iex> Giraffe.Graph.new(type: :directed)
      %Giraffe.Graph{impl: %Giraffe.Graph.Directed{vertices: MapSet.new([]), edges: %{}}, type: :directed}

      iex> Giraffe.Graph.new(type: :undirected)
      %Giraffe.Graph{impl: %Giraffe.Graph.Undirected{vertices: MapSet.new([]), edges: %{}}, type: :undirected}
  """
  @spec new(type: :directed) :: t()
  def new(type: :directed),
    do: %__MODULE__{type: :directed, impl: Giraffe.Graph.Directed.new()}

  @spec new(type: :undirected) :: t()
  def new(type: :undirected),
    do: %__MODULE__{type: :undirected, impl: Giraffe.Graph.Undirected.new()}

  @doc """
  Adds a new vertex to the graph with optional label.

  ## Examples

      iex> graph = Giraffe.Graph.new(type: :directed)
      iex> Giraffe.Graph.add_vertex(graph, :a, "vertex A")
      %Giraffe.Graph{impl: %Giraffe.Graph.Directed{vertices: MapSet.new([:a]), edges: %{}, labels: %{a: "vertex A"}}, type: :directed}
  """
  @spec add_vertex(t(), vertex(), label()) :: t()
  def add_vertex(%__MODULE__{type: type, impl: impl} = graph, vertex, label \\ nil) do
    %{graph | impl: apply_impl(type, :add_vertex, [impl, vertex, label])}
  end

  @doc """
  Gets the label associated with a vertex.

  ## Examples

      iex> graph = Giraffe.Graph.new(type: :directed) |> Giraffe.Graph.add_vertex(:a, "label A")
      iex> Giraffe.Graph.get_label(graph, :a)
      "label A"
  """
  @spec get_label(t(), vertex()) :: label() | nil
  def get_label(%__MODULE__{type: type, impl: impl}, vertex) do
    apply_impl(type, :get_label, [impl, vertex])
  end

  @doc """
  Sets a label for an existing vertex.

  ## Examples

      iex> graph = Giraffe.Graph.new(type: :directed) |> Giraffe.Graph.add_vertex(:a)
      iex> Giraffe.Graph.set_label(graph, :a, "new label")
      %Giraffe.Graph{impl: %Giraffe.Graph.Directed{vertices: MapSet.new([:a]), edges: %{}, labels: %{a: "new label"}}, type: :directed}
  """
  @spec set_label(t(), vertex(), label()) :: t()
  def set_label(%__MODULE__{type: type, impl: impl} = graph, vertex, label) do
    %{graph | impl: apply_impl(type, :set_label, [impl, vertex, label])}
  end

  @doc """
  Adds an edge between two vertices with optional weight.

  ## Examples

      iex> graph = Giraffe.Graph.new(type: :directed)
      iex> Giraffe.Graph.add_edge(graph, :a, :b, 2.5)
      %Giraffe.Graph{impl: %Giraffe.Graph.Directed{vertices: MapSet.new([:a, :b]), edges: %{a: %{b: 2.5}}}, type: :directed}
  """
  @spec add_edge(t(), vertex(), vertex(), weight()) :: t()
  def add_edge(%__MODULE__{type: type, impl: impl} = graph, from, to, weight \\ 1) do
    %{graph | impl: apply_impl(type, :add_edge, [impl, from, to, weight])}
  end

  @doc """
  Returns a list of all vertices in the graph.

  ## Examples

      iex> graph = Giraffe.Graph.new(type: :directed) |> Giraffe.Graph.add_vertex(:a)
      iex> Giraffe.Graph.vertices(graph)
      [:a]
  """
  @spec vertices(t()) :: [vertex()]
  def vertices(%__MODULE__{type: type, impl: impl}) do
    apply_impl(type, :vertices, [impl])
  end

  @doc """
  Returns a list of all edges in the graph.

  ## Examples

      iex> graph = Giraffe.Graph.new(type: :directed) |> Giraffe.Graph.add_edge(:a, :b, 1)
      iex> Giraffe.Graph.edges(graph)
      [{:a, :b, 1}]
  """
  @spec edges(t()) :: [edge()]
  def edges(%__MODULE__{type: type, impl: impl}) do
    apply_impl(type, :edges, [impl])
  end

  @doc """
  Returns a list of all edges connected to the given vertex.

  ## Examples

      iex> graph = Giraffe.Graph.new(type: :directed) |> Giraffe.Graph.add_edge(:a, :b, 1)
      iex> Giraffe.Graph.edges(graph, :a)
      [{:a, :b, 1}]
  """
  @spec edges(t(), vertex()) :: [edge()]
  def edges(%__MODULE__{type: type, impl: impl}, v) do
    apply_impl(type, :edges, [impl, v])
  end

  @doc """
  Returns a list of edges between two vertices.
  """
  @spec edges(t(), vertex(), vertex()) :: [edge()]
  def edges(%__MODULE__{type: type, impl: impl}, v1, v2) do
    apply_impl(type, :edges, [impl, v1, v2])
  end

  @doc """
  Returns the total number of edges in the graph.

  ## Examples

      iex> graph = Giraffe.Graph.new(type: :directed) |> Giraffe.Graph.add_edge(:a, :b, 1)
      iex> Giraffe.Graph.num_edges(graph)
      1
  """
  @spec num_edges(t()) :: non_neg_integer()
  def num_edges(%__MODULE__{type: type, impl: impl}) do
    apply_impl(type, :num_edges, [impl])
  end

  @doc """
  Returns the total number of vertices in the graph.

  ## Examples

      iex> graph = Giraffe.Graph.new(type: :directed) |> Giraffe.Graph.add_vertex(:a)
      iex> Giraffe.Graph.num_vertices(graph)
      1
  """
  @spec num_vertices(t()) :: non_neg_integer()
  def num_vertices(%__MODULE__{type: type, impl: impl}) do
    apply_impl(type, :num_vertices, [impl])
  end

  @doc """
  Returns true if the vertex exists in the graph.

  ## Examples

      iex> graph = Giraffe.Graph.new(type: :directed) |> Giraffe.Graph.add_vertex(:a)
      iex> Giraffe.Graph.has_vertex?(graph, :a)
      true
  """
  @spec has_vertex?(t(), vertex()) :: boolean()
  def has_vertex?(%__MODULE__{type: type, impl: impl}, vertex) do
    apply_impl(type, :has_vertex?, [impl, vertex])
  end

  @doc """
  Gets the shortest path between two vertices.

  ## Examples

      iex> graph = Giraffe.Graph.new(type: :directed) |> Giraffe.Graph.add_edge(:a, :b, 1)
      iex> Giraffe.Graph.get_shortest_path(graph, :a, :b)
      {:ok, [:a, :b], 1}
  """
  @spec get_shortest_path(t(), vertex(), vertex()) :: {:ok, [vertex()], number()} | :no_path
  def get_shortest_path(%__MODULE__{type: type, impl: impl}, start, finish) do
    apply_impl(type, :get_shortest_path, [impl, start, finish])
  end

  @doc """
  Gets all paths between two vertices.

  ## Examples

      iex> graph = Giraffe.Graph.new(type: :directed) |> Giraffe.Graph.add_edge(:a, :b, 1)
      iex> Giraffe.Graph.get_paths(graph, :a, :b)
      [{[:a, :b], 1.0}]
  """
  @spec get_paths(t(), vertex(), vertex()) :: [{[vertex()], number()}]
  def get_paths(%__MODULE__{type: type, impl: impl}, start, finish) do
    apply_impl(type, :get_paths, [impl, start, finish])
  end

  @doc """
  Returns a list of neighboring vertices.

  ## Examples

      iex> graph = Giraffe.Graph.new(type: :directed) |> Giraffe.Graph.add_edge(:a, :b, 1)
      iex> Giraffe.Graph.neighbors(graph, :a)
      [:b]
  """
  @spec neighbors(t(), vertex()) :: [vertex()]
  def neighbors(%__MODULE__{type: type, impl: impl}, vertex) do
    apply_impl(type, :neighbors, [impl, vertex])
  end

  @doc """
  Returns a list of vertices reachable from the given vertices.

  ## Examples

      iex> graph = Giraffe.Graph.new(type: :directed) |> Giraffe.Graph.add_edge(:a, :b, 1)
      iex> Giraffe.Graph.reachable(graph, [:a])
      [:a, :b]
  """
  @spec reachable(t(), [vertex()]) :: [vertex()]
  def reachable(%__MODULE__{type: type, impl: impl}, vertices) do
    apply_impl(type, :reachable, [impl, vertices])
  end

  @doc """
  Returns true if the graph is acyclic.

  ## Examples

      iex> graph = Giraffe.Graph.new(type: :directed) |> Giraffe.Graph.add_edge(:a, :b, 1)
      iex> Giraffe.Graph.is_acyclic?(graph)
      true
  """
  @spec is_acyclic?(t()) :: boolean()
  def is_acyclic?(%__MODULE__{type: type, impl: impl}) do
    apply_impl(type, :is_acyclic?, [impl])
  end

  @doc """
  Returns true if the graph contains cycles.

  ## Examples

      iex> graph = Giraffe.Graph.new(type: :directed) |> Giraffe.Graph.add_edge(:a, :a, 1)
      iex> Giraffe.Graph.is_cyclic?(graph)
      true
  """
  @spec is_cyclic?(t()) :: boolean()
  def is_cyclic?(%__MODULE__{type: type, impl: impl}) do
    apply_impl(type, :is_cyclic?, [impl])
  end

  @doc """
  Finds shortest paths from source vertex using Bellman-Ford algorithm.

  ## Examples

      iex> graph = Giraffe.Graph.new(type: :directed) |> Giraffe.Graph.add_edge(:a, :b, 1)
      iex> Giraffe.Graph.bellman_ford(graph, :a)
      %{a: 0, b: 1}
  """
  @spec bellman_ford(t(), vertex()) :: %{vertex() => number()} | nil
  def bellman_ford(%__MODULE__{type: type, impl: impl}, source) do
    apply_impl(type, :bellman_ford, [impl, source])
  end

  @doc """
  Gets the shortest path between two vertices using Dijkstra's algorithm.

  ## Examples

      iex> graph = Giraffe.Graph.new(type: :directed) |> Giraffe.Graph.add_edge(:a, :b, 1)
      iex> Giraffe.Graph.dijkstra(graph, :a, :b)
      {:ok, [:a, :b], 1}
  """
  @spec dijkstra(t(), vertex(), vertex()) :: {:ok, [vertex()], number()} | :no_path
  def dijkstra(%__MODULE__{} = graph, a, b) do
    get_shortest_path(graph, a, b)
  end

  @doc """
  Returns the labels for the given vertex.

  ## Examples

      iex> graph = Giraffe.Graph.new(type: :directed) |> Giraffe.Graph.add_vertex(:a, [:label])
      iex> Giraffe.Graph.vertex_labels(graph, :a)
      [:label]
  """
  @spec vertex_labels(t(), vertex()) :: [label()]
  def vertex_labels(%__MODULE__{type: type, impl: impl}, vertex) do
    apply_impl(type, :vertex_labels, [impl, vertex])
  end

  defp apply_impl(:directed, function, args) do
    apply(Giraffe.Graph.Directed, function, args)
  end

  defp apply_impl(:undirected, function, args) do
    apply(Giraffe.Graph.Undirected, function, args)
  end
end
