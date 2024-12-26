defmodule Giraffe.Graph.Directed do
  @moduledoc """
  Implementation of a directed graph with weighted edges.
  Vertices can be any term, and edges have numeric weights.
  """

  defstruct vertices: MapSet.new(),
            edges: %{}

  @type vertex :: any()
  @type weight :: number()
  @type edge :: {vertex(), vertex(), weight()}
  @type t :: %__MODULE__{
          vertices: MapSet.t(),
          edges: %{vertex() => %{vertex() => weight()}}
        }

  @doc """
  Creates a new empty directed graph.
  """
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc """
  Adds a vertex to the graph.
  """
  @spec add_vertex(t(), vertex()) :: t()
  def add_vertex(%__MODULE__{vertices: vertices} = graph, vertex) do
    %{graph | vertices: MapSet.put(vertices, vertex)}
  end

  @doc """
  Adds a weighted edge between two vertices in the graph.
  The vertices will be added to the graph if they don't already exist.
  """
  @spec add_edge(t(), vertex(), vertex(), weight()) :: t()
  def add_edge(%__MODULE__{edges: edges, vertices: vertices} = graph, from, to, weight) do
    new_vertices =
      vertices
      |> MapSet.put(from)
      |> MapSet.put(to)

    new_edges =
      Map.update(edges, from, %{to => weight}, fn map ->
        Map.put(map, to, weight)
      end)

    %{graph | edges: new_edges, vertices: new_vertices}
  end

  @doc """
  Returns a list of all vertices in the graph.
  """
  @spec vertices(t()) :: [vertex()]
  def vertices(%__MODULE__{vertices: vertices}), do: MapSet.to_list(vertices)

  @doc """
  Returns a list of all edges in the graph as tuples of {from, to, weight}.
  """
  @spec edges(t()) :: [edge()]
  def edges(%__MODULE__{edges: edges}) do
    edges
    |> Enum.flat_map(fn {from, targets} ->
      Enum.map(targets, fn {to, weight} -> {from, to, weight} end)
    end)
  end

  @doc """
  Finds the shortest path between two vertices using Dijkstra's algorithm.
  Returns {:ok, path, total_weight} if a path exists, or :no_path if no path exists.
  """
  @spec get_shortest_path(t(), vertex(), vertex()) :: {:ok, [vertex()], weight()} | :no_path
  def get_shortest_path(%__MODULE__{edges: edges, vertices: vertices}, start, finish) do
    # Initialize distances map with infinity for all vertices except start
    distances = Enum.reduce(vertices, %{}, fn v, acc -> Map.put(acc, v, :infinity) end)
    distances = Map.put(distances, start, 0)

    # Initialize empty predecessors map
    predecessors = %{}

    # Priority queue with {vertex, distance} tuples, starting with just the start vertex
    queue = :gb_sets.singleton({0, start})

    {final_distances, final_predecessors} =
      dijkstra_loop(queue, distances, predecessors, edges, finish)

    case Map.get(final_distances, finish) do
      :infinity ->
        :no_path

      distance ->
        path = build_path(final_predecessors, finish)
        {:ok, path, distance}
    end
  end

  @doc """
  Finds all possible paths between two vertices.
  Returns a list of tuples containing the path and its total weight.
  """
  @spec get_paths(t(), vertex(), vertex()) :: [{[vertex()], weight()}]
  def get_paths(graph, start, finish) do
    find_all_paths(graph, start, finish, [start], MapSet.new([start]), 0.0)
  end

  @doc """
  Finds all maximal cliques in the graph.
  A clique is a subset of vertices where every vertex is connected to every other vertex.
  Only considers bidirectional edges.
  """
  @spec cliques(t()) :: [[vertex()]]
  def cliques(%__MODULE__{vertices: vertices, edges: edges}) do
    undirected_edges = to_undirected_edges(edges)
    Giraffe.Algorithms.BronKerbosch.find_cliques(MapSet.to_list(vertices), undirected_edges)
  end

  @doc """
  Finds the shortest paths from a source vertex to all other vertices using the Bellman-Ford algorithm.
  Returns {:ok, distances} with distances from source to all reachable vertices, or {:error, :negative_cycle}
  if a negative cycle is detected.
  """
  def shortest_paths(graph, source) do
    Giraffe.Algorithms.BellmanFord.shortest_paths(
      graph,
      source
    )
  end

  # Private Functions

  @doc false
  @spec to_undirected_edges(%{vertex() => %{vertex() => weight()}}) :: %{
          vertex() => %{vertex() => weight()}
        }
  defp to_undirected_edges(edges) do
    Enum.reduce(edges, %{}, fn {from, targets}, acc ->
      Enum.reduce(targets, acc, fn {to, weight}, inner_acc ->
        if bidirectional?(edges, from, to) do
          inner_acc
          |> Map.update(from, %{to => weight}, &Map.put(&1, to, weight))
          |> Map.update(to, %{from => weight}, &Map.put(&1, from, weight))
        else
          inner_acc
        end
      end)
    end)
  end

  @doc false
  @spec bidirectional?(%{vertex() => %{vertex() => weight()}}, vertex(), vertex()) :: boolean()
  defp bidirectional?(edges, v1, v2) do
    has_edge?(edges, v1, v2) and has_edge?(edges, v2, v1)
  end

  @doc false
  @spec has_edge?(%{vertex() => %{vertex() => weight()}}, vertex(), vertex()) :: boolean()
  defp has_edge?(edges, from, to) do
    edges |> Map.get(from, %{}) |> Map.has_key?(to)
  end

  @doc false
  @spec dijkstra_loop(
          :gb_sets.set(),
          map(),
          map(),
          %{vertex() => %{vertex() => weight()}},
          vertex()
        ) :: {map(), map()}
  defp dijkstra_loop(queue, distances, predecessors, edges, target) do
    case :gb_sets.is_empty(queue) do
      true ->
        {distances, predecessors}

      false ->
        {{current_distance, current}, rest} = :gb_sets.take_smallest(queue)

        if current == target do
          {distances, predecessors}
        else
          neighbors = Map.get(edges, current, %{})

          {new_distances, new_predecessors, new_queue} =
            Enum.reduce(neighbors, {distances, predecessors, rest}, fn {neighbor, weight},
                                                                       {dist_acc, pred_acc,
                                                                        queue_acc} ->
              alt = current_distance + weight

              if alt < Map.get(dist_acc, neighbor, :infinity) do
                new_dist = Map.put(dist_acc, neighbor, alt)
                new_pred = Map.put(pred_acc, neighbor, current)
                new_queue = :gb_sets.add({alt, neighbor}, queue_acc)
                {new_dist, new_pred, new_queue}
              else
                {dist_acc, pred_acc, queue_acc}
              end
            end)

          dijkstra_loop(new_queue, new_distances, new_predecessors, edges, target)
        end
    end
  end

  @spec build_path(map(), vertex()) :: [vertex()]
  defp build_path(predecessors, target) do
    build_path_recursive(predecessors, target, [target])
  end

  @spec build_path_recursive(map(), vertex(), [vertex()]) :: [vertex()]
  defp build_path_recursive(predecessors, current, path) do
    case Map.get(predecessors, current) do
      nil -> path
      predecessor -> build_path_recursive(predecessors, predecessor, [predecessor | path])
    end
  end

  @spec find_all_paths(t(), vertex(), vertex(), [vertex()], MapSet.t(), weight()) :: [
          {[vertex()], weight()}
        ]
  defp find_all_paths(_graph, current, finish, path, _visited, weight) when current == finish do
    [{Enum.reverse(path), weight}]
  end

  defp find_all_paths(%__MODULE__{edges: edges}, current, finish, path, visited, weight) do
    neighbors = Map.get(edges, current, %{})

    neighbors
    |> Enum.flat_map(fn {neighbor, edge_weight} ->
      if not MapSet.member?(visited, neighbor) do
        find_all_paths(
          %__MODULE__{edges: edges},
          neighbor,
          finish,
          [neighbor | path],
          MapSet.put(visited, neighbor),
          weight + edge_weight
        )
      else
        []
      end
    end)
  end
end
