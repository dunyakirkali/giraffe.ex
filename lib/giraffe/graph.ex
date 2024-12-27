defmodule Giraffe.Graph do
  @moduledoc """
  Public interface for working with graphs. Delegates to specific implementations
  based on whether the graph is directed or undirected.
  """

  defstruct [:type, :impl]

  @type vertex :: any()
  @type weight :: number()
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

  @spec add_vertex(t(), vertex()) :: t()
  def add_vertex(%__MODULE__{type: type, impl: impl} = graph, vertex) do
    %{graph | impl: apply_impl(type, :add_vertex, [impl, vertex])}
  end

  @spec add_edge(t(), vertex(), vertex(), weight()) :: t()
  def add_edge(%__MODULE__{type: type, impl: impl} = graph, from, to, weight \\ 1) do
    %{graph | impl: apply_impl(type, :add_edge, [impl, from, to, weight])}
  end

  @spec vertices(t()) :: [vertex()]
  def vertices(%__MODULE__{type: type, impl: impl}) do
    apply_impl(type, :vertices, [impl])
  end

  @spec edges(t()) :: [edge()]
  def edges(%__MODULE__{type: type, impl: impl}) do
    apply_impl(type, :edges, [impl])
  end

  @spec get_shortest_path(t(), vertex(), vertex()) :: [vertex()] | nil
  def get_shortest_path(%__MODULE__{type: type, impl: impl}, start, finish) do
    apply_impl(type, :get_shortest_path, [impl, start, finish])
  end

  @spec get_paths(t(), vertex(), vertex()) :: [[vertex()]]
  def get_paths(%__MODULE__{type: type, impl: impl}, start, finish) do
    apply_impl(type, :get_paths, [impl, start, finish])
  end

  @doc """
  Returns a list of vertices that are reachable from any of the given vertices.

  Includes the starting vertices themselves as paths of length zero are allowed.

  ## Examples

      iex> g = Giraffe.Graph.new(type: :directed)
      ...> g = g |> Giraffe.Graph.add_edge(1, 2) |> Giraffe.Graph.add_edge(2, 3)
      ...> Giraffe.Graph.reachable(g, [1])
      [1, 2, 3]

      iex> g = Giraffe.Graph.new(type: :undirected)
      ...> g = g |> Giraffe.Graph.add_edge(1, 2) |> Giraffe.Graph.add_edge(2, 3)
      ...> Giraffe.Graph.reachable(g, [3])
      [1, 2, 3]
  """
  @spec reachable(t(), [vertex()]) :: [vertex()]
  def reachable(%__MODULE__{type: type, impl: impl}, vertices) do
    apply_impl(type, :reachable, [impl, vertices])
  end

  defp apply_impl(:directed, function, args) do
    apply(Giraffe.Graph.Directed, function, args)
  end

  defp apply_impl(:undirected, function, args) do
    apply(Giraffe.Graph.Undirected, function, args)
  end
end
