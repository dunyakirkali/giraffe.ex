defmodule Giraffe.Graph.Directed do
  @moduledoc """
  Implementation of a directed graph with weighted edges.
  Vertices can be any term, and edges have numeric weights.

  ## Examples

      iex> graph = Giraffe.Graph.Directed.new()
      ...> graph = graph |> Giraffe.Graph.Directed.add_edge(:a, :b, 1)
      ...> graph |> Giraffe.Graph.Directed.edges()
      [{:a, :b, 1}]
  """

  use Giraffe.Graph.Base

  @doc """
  Adds a weighted edge between two vertices in the graph.
  The vertices will be added to the graph if they don't already exist.

  ## Examples

      iex> graph = Giraffe.Graph.Directed.new()
      ...> graph = Giraffe.Graph.Directed.add_edge(graph, :a, :b, 1)
      ...> Giraffe.Graph.Directed.edges(graph)
      [{:a, :b, 1}]
  """
  @spec add_edge(t(), vertex(), vertex(), number() | keyword()) :: t()
  def add_edge(graph, v1, v2, opts_or_weight \\ 1) do
    weight =
      case opts_or_weight do
        opts when is_list(opts) -> Keyword.get(opts, :weight, 1)
        weight when is_number(weight) -> weight
      end

    graph = add_vertex(graph, v1)
    graph = add_vertex(graph, v2)

    %{graph | edges: Map.update(graph.edges, v1, %{v2 => weight}, &Map.put(&1, v2, weight))}
  end

  @doc "Gets the shortest path between a and b using Dijkstra's algorithm"
  @spec dijkstra(t(), vertex(), vertex()) :: {:ok, [vertex()], number()} | :no_path
  def dijkstra(graph, a, b), do: get_shortest_path(graph, a, b)

  @doc """
  Returns a list of all edges in the graph as tuples of {from, to, weight}.

  ## Examples

      iex> graph = Giraffe.Graph.Directed.new()
      ...> graph = Giraffe.Graph.Directed.add_edge(graph, :a, :b, 1)
      ...> Giraffe.Graph.Directed.edges(graph)
      [{:a, :b, 1}]
  """
  @spec edges(t()) :: [{vertex(), vertex(), number()}]
  def edges(%__MODULE__{edges: edges}) do
    edges
    |> Enum.flat_map(fn {from, targets} ->
      Enum.map(targets, fn {to, weight} -> {from, to, weight} end)
    end)
  end

  @doc """
  Returns a list of all edges for a specific vertex.

  ## Examples

      iex> graph = Giraffe.Graph.Directed.new()
      ...> graph = Giraffe.Graph.Directed.add_edge(graph, :a, :b, 1)
      ...> Giraffe.Graph.Directed.edges(graph, :a)
      [{:a, :b, 1}]
  """
  @spec edges(t(), vertex()) :: [{vertex(), vertex(), number()}]
  def edges(%__MODULE__{edges: edges}, vertex) do
    outgoing =
      Map.get(edges, vertex, %{})
      |> Enum.map(fn {to, weight} -> {vertex, to, weight} end)

    incoming =
      edges
      |> Enum.flat_map(fn {from, targets} ->
        case Map.get(targets, vertex) do
          nil -> []
          weight -> [{from, vertex, weight}]
        end
      end)

    outgoing ++ incoming
  end

  @doc "Finds shortest paths using Bellman-Ford algorithm"
  @spec bellman_ford(t(), vertex()) :: %{vertex() => number()} | nil
  def bellman_ford(graph, source) do
    case shortest_paths(graph, source) do
      {:ok, distances} -> distances
      {:error, :negative_cycle} -> nil
    end
  end

  @doc """
  Finds the shortest path between two vertices using Dijkstra's algorithm.
  Returns {:ok, path, total_weight} if a path exists, or :no_path if no path exists.

  ## Examples

      iex> graph = Giraffe.Graph.Directed.new()
      ...> graph = graph |> Giraffe.Graph.Directed.add_edge(:a, :b, 1)
      ...> Giraffe.Graph.Directed.get_shortest_path(graph, :a, :b)
      {:ok, [:a, :b], 1}
  """
  @spec get_shortest_path(t(), vertex(), vertex()) :: {:ok, [vertex()], weight()} | :no_path
  def get_shortest_path(%__MODULE__{edges: edges, vertices: vertices}, start, finish) do
    if not MapSet.member?(vertices, start) or not MapSet.member?(vertices, finish) do
      :no_path
    else
      # Initialize distances and predecessors
      distances = Map.new(vertices, fn v -> {v, if(v == start, do: 0, else: :infinity)} end)
      predecessors = %{}

      # Initialize priority queue with start vertex
      queue = Giraffe.PriorityQueue.new() |> Giraffe.PriorityQueue.enqueue(0, start)

      # Run Dijkstra's algorithm
      case dijkstra_loop(queue, distances, predecessors, edges, finish) do
        {distances, predecessors} ->
          case Map.get(distances, finish) do
            :infinity -> :no_path
            distance -> {:ok, build_path(predecessors, finish), distance}
          end
      end
    end
  end

  @doc """
  Finds all possible paths between two vertices.
  Returns a list of tuples containing the path and its total weight.

  ## Examples

      iex> graph = Giraffe.Graph.Directed.new()
      ...> graph = graph |> Giraffe.Graph.Directed.add_edge(:a, :b, 1)
      ...> Giraffe.Graph.Directed.get_paths(graph, :a, :b)
      [{[:a, :b], 1.0}]
  """
  @spec get_paths(t(), vertex(), vertex()) :: [{[vertex()], weight()}]
  def get_paths(graph, start, finish) do
    find_all_paths(graph, start, finish, [start], MapSet.new([start]), 0.0)
  end

  @doc """
  Finds all maximal cliques in the graph.
  A clique is a subset of vertices where every vertex is connected to every other vertex.
  Only considers bidirectional edges.

  ## Examples

      iex> graph = Giraffe.Graph.Directed.new()
      ...> graph = graph |> Giraffe.Graph.Directed.add_edge(:a, :b, 1)
      ...> graph = graph |> Giraffe.Graph.Directed.add_edge(:b, :a, 1)
      ...> Giraffe.Graph.Directed.cliques(graph)
      [[:a, :b]]
  """
  @spec cliques(t()) :: [[vertex()]]
  def cliques(%__MODULE__{vertices: vertices, edges: edges}) do
    undirected_edges = to_undirected_edges(edges)
    Giraffe.Algorithms.BronKerbosch.find_cliques(MapSet.to_list(vertices), undirected_edges)
  end

  @doc """
  Finds the shortest paths from a source vertex to all other vertices using the Bellman-Ford algorithm.

  ## Examples

      iex> graph = Giraffe.Graph.Directed.new()
      ...> graph = graph |> Giraffe.Graph.Directed.add_edge(:a, :b, 1)
      ...> Giraffe.Graph.Directed.shortest_paths(graph, :a)
      {:ok, %{a: 0, b: 1}}
  """
  @spec shortest_paths(t(), vertex()) ::
          {:ok, %{vertex() => weight()}} | {:error, :negative_cycle}
  def shortest_paths(graph, source) do
    Giraffe.Algorithms.BellmanFord.shortest_paths(graph, source)
  end

  @doc """
  Checks if the graph is acyclic.

  ## Examples

      iex> graph = Giraffe.Graph.Directed.new()
      ...> graph = graph |> Giraffe.Graph.Directed.add_edge(:a, :b, 1)
      ...> Giraffe.Graph.Directed.is_acyclic?(graph)
      true
  """
  @spec is_acyclic?(t()) :: boolean()
  def is_acyclic?(%__MODULE__{edges: edges, vertices: vertices}) do
    vertices = MapSet.to_list(vertices)
    visited = Map.new(vertices, fn v -> {v, :unvisited} end)
    recurse_vertices(vertices, visited, edges)
  end

  @doc """
  Checks if the graph is cyclic.

  ## Examples

      iex> graph = Giraffe.Graph.Directed.new()
      ...> graph = graph |> Giraffe.Graph.Directed.add_edge(:a, :b, 1)
      ...> graph = graph |> Giraffe.Graph.Directed.add_edge(:b, :a, 1)
      ...> Giraffe.Graph.Directed.is_cyclic?(graph)
      true
  """
  @spec is_cyclic?(t()) :: boolean()
  def is_cyclic?(graph), do: not is_acyclic?(graph)

  @doc """
  Returns a sorted list of all vertices that are neighbors of the given vertex.
  Includes both incoming and outgoing edges.

  ## Examples

      iex> graph = Giraffe.Graph.Directed.new()
      ...> graph = graph |> Giraffe.Graph.Directed.add_edge(:a, :b, 1)
      ...> Giraffe.Graph.Directed.neighbors(graph, :a)
      [:b]
  """
  @spec neighbors(t(), vertex()) :: [vertex()]
  def neighbors(%__MODULE__{edges: edges}, vertex) do
    outgoing = Map.get(edges, vertex, %{}) |> Map.keys()

    incoming =
      edges
      |> Enum.filter(fn {_, targets} -> Map.has_key?(targets, vertex) end)
      |> Enum.map(fn {source, _} -> source end)

    (outgoing ++ incoming)
    |> Enum.uniq()
    |> Enum.sort()
  end

  # Private Functions

  defp dijkstra_loop(queue, distances, predecessors, edges, target) do
    case Giraffe.PriorityQueue.dequeue(queue) do
      :empty ->
        {distances, predecessors}

      {current, rest} ->
        if current == target do
          {distances, predecessors}
        else
          current_distance = Map.get(distances, current)
          neighbors = Map.get(edges, current, %{})

          {new_distances, new_predecessors, new_queue} =
            Enum.reduce(neighbors, {distances, predecessors, rest}, fn {neighbor, weight},
                                                                       {dist_acc, pred_acc,
                                                                        queue_acc} ->
              alt = current_distance + weight

              if alt < Map.get(dist_acc, neighbor, :infinity) do
                {
                  Map.put(dist_acc, neighbor, alt),
                  Map.put(pred_acc, neighbor, current),
                  Giraffe.PriorityQueue.enqueue(queue_acc, alt, neighbor)
                }
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

  @spec to_undirected_edges(map()) :: map()
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

  @spec bidirectional?(map(), vertex(), vertex()) :: boolean()
  defp bidirectional?(edges, v1, v2) do
    has_edge?(edges, v1, v2) and has_edge?(edges, v2, v1)
  end

  @spec has_edge?(map(), vertex(), vertex()) :: boolean()
  defp has_edge?(edges, from, to) do
    edges |> Map.get(from, %{}) |> Map.has_key?(to)
  end

  @spec recurse_vertices([vertex()], map(), map()) :: boolean()
  defp recurse_vertices([], _visited, _edges), do: true

  defp recurse_vertices([v | rest], visited, edges) do
    case Map.get(visited, v) do
      :unvisited ->
        {has_cycle, new_visited} = has_cycle?(v, edges, visited, MapSet.new())
        if has_cycle, do: false, else: recurse_vertices(rest, new_visited, edges)

      _ ->
        recurse_vertices(rest, visited, edges)
    end
  end

  @spec has_cycle?(vertex(), map(), map(), MapSet.t()) :: {boolean(), map()}
  defp has_cycle?(vertex, edges, visited, path) do
    if MapSet.member?(path, vertex) do
      {true, visited}
    else
      visited = Map.put(visited, vertex, :visited)
      path = MapSet.put(path, vertex)
      neighbors = Map.get(edges, vertex, %{})

      Enum.reduce_while(neighbors, {false, visited}, fn {neighbor, _weight},
                                                        {_cycle, acc_visited} ->
        case Map.get(acc_visited, neighbor) do
          :unvisited ->
            {has_cycle, new_visited} = has_cycle?(neighbor, edges, acc_visited, path)
            if has_cycle, do: {:halt, {true, new_visited}}, else: {:cont, {false, new_visited}}

          _ ->
            if MapSet.member?(path, neighbor) do
              {:halt, {true, acc_visited}}
            else
              {:cont, {false, acc_visited}}
            end
        end
      end)
    end
  end

  @spec find_all_paths(t(), vertex(), vertex(), [vertex()], MapSet.t(), weight()) :: [
          {[vertex()], weight()}
        ]
  defp find_all_paths(_graph, current, finish, path, _visited, weight)
       when current == finish do
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
