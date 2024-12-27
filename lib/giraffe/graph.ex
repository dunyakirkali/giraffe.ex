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
  @spec new(keyword()) :: t()
  def new(type: :directed),
    do: %__MODULE__{type: :directed, impl: Giraffe.Graph.Directed.new()}

  def new(type: :undirected),
    do: %__MODULE__{type: :undirected, impl: Giraffe.Graph.Undirected.new()}

  def add_vertex(%__MODULE__{type: type, impl: impl} = graph, vertex) do
    %{graph | impl: apply_impl(type, :add_vertex, [impl, vertex])}
  end

  def add_edge(%__MODULE__{type: type, impl: impl} = graph, from, to, weight \\ 1) do
    %{graph | impl: apply_impl(type, :add_edge, [impl, from, to, weight])}
  end

  def vertices(%__MODULE__{type: type, impl: impl}) do
    apply_impl(type, :vertices, [impl])
  end

  def edges(%__MODULE__{type: type, impl: impl}) do
    apply_impl(type, :edges, [impl])
  end

  def get_shortest_path(%__MODULE__{type: type, impl: impl}, start, finish) do
    apply_impl(type, :get_shortest_path, [impl, start, finish])
  end

  def get_paths(%__MODULE__{type: type, impl: impl}, start, finish) do
    apply_impl(type, :get_paths, [impl, start, finish])
  end

  defp apply_impl(:directed, function, args) do
    apply(Giraffe.Graph.Directed, function, args)
  end

  defp apply_impl(:undirected, function, args) do
    apply(Giraffe.Graph.Undirected, function, args)
  end
end
