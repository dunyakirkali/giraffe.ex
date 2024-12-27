defmodule Giraffe.Graph.Undirected do
  @moduledoc """
  Implementation of an undirected graph with weighted edges.
  Vertices can be any term, and edges have numeric weights.
  """

  use Giraffe.Graph.Base

  @doc """
  Adds an edge between two vertices with the given weight.
  If the vertices don't exist, they will be added to the graph.
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

    %{
      graph
      | edges:
          graph.edges
          |> Map.update(v1, %{v2 => weight}, &Map.put(&1, v2, weight))
          |> Map.update(v2, %{v1 => weight}, &Map.put(&1, v1, weight))
    }
  end

  @doc """
  Returns a list of all edges in the graph as tuples of {from, to, weight}.

  ## Examples

      iex> graph = Giraffe.Graph.Undirected.new()
      ...> graph = Giraffe.Graph.Undirected.add_edge(graph, :a, :b, 1)
      ...> Giraffe.Graph.Undirected.edges(graph)
      [{:a, :b, 1}]
  """
  @spec edges(t()) :: [{vertex(), vertex(), number()}]
  def edges(%__MODULE__{edges: edges}) do
    edges
    |> Enum.flat_map(fn {v1, targets} ->
      Enum.map(targets, fn {v2, weight} ->
        if v1 <= v2, do: {v1, v2, weight}, else: {v2, v1, weight}
      end)
    end)
    |> Enum.uniq()
  end

  @doc """
  Returns a list of all edges for a specific vertex.

  ## Examples

      iex> graph = Giraffe.Graph.Undirected.new()
      ...> graph = Giraffe.Graph.Undirected.add_edge(graph, :a, :b, 1)
      ...> Giraffe.Graph.Undirected.edges(graph, :a)
      [{:a, :b, 1}]
  """
  @spec edges(t(), vertex()) :: [{vertex(), vertex(), number()}]
  def edges(%__MODULE__{edges: edges}, vertex) do
    case Map.get(edges, vertex) do
      nil ->
        []

      targets ->
        Enum.map(targets, fn {other_vertex, weight} ->
          if vertex <= other_vertex,
            do: {vertex, other_vertex, weight},
            else: {other_vertex, vertex, weight}
        end)
    end
  end

  @doc """
  Finds shortest paths from a source vertex using the Bellman-Ford algorithm.
  Returns nil if a negative cycle is detected.

  ## Examples

      iex> graph = Giraffe.Graph.Undirected.new()
      ...> graph = graph |> Giraffe.Graph.Undirected.add_edge(:a, :b, 1)
      ...> graph |> Giraffe.Graph.Undirected.bellman_ford(:a)
      %{a: 0, b: 1}
  """
  @spec bellman_ford(t(), vertex()) :: %{vertex() => number()} | nil
  def bellman_ford(graph, source) do
    case shortest_paths(graph, source) do
      {:ok, distances} -> distances
      {:error, :negative_cycle} -> nil
    end
  end

  @doc """
  Finds the shortest path between two vertices using Dijkstra's algorithm.
  Returns {:ok, path, total_weight} if a path exists, :no_path otherwise.
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
  """
  @spec get_paths(t(), vertex(), vertex()) :: [{[vertex()], weight()}]
  def get_paths(graph, start, finish) do
    find_all_paths(graph, start, finish, [start], MapSet.new([start]), 0.0)
  end

  @doc """
  Detects all maximal cliques in the graph using the Bron-Kerbosch algorithm.
  """
  @spec cliques(t()) :: [[vertex()]]
  def cliques(%__MODULE__{vertices: vertices, edges: _edges} = graph) do
    bron_kerbosch(MapSet.new(), MapSet.new(vertices), MapSet.new(), graph)
  end

  @doc """
  Finds shortest paths using Bellman-Ford algorithm.
  """
  def shortest_paths(graph, source) do
    Giraffe.Algorithms.BellmanFord.shortest_paths(graph, source)
  end

  @doc """
  Checks if the graph is acyclic (contains no cycles).
  """
  @spec is_acyclic?(t()) :: boolean()
  def is_acyclic?(%__MODULE__{vertices: vertices, edges: edges}) do
    vertices_list = MapSet.to_list(vertices)
    visited = MapSet.new()
    parent = %{}

    Enum.reduce_while(vertices_list, {visited, parent, true}, fn vertex, {visited, parent, _} ->
      if MapSet.member?(visited, vertex) do
        {:cont, {visited, parent, true}}
      else
        case dfs_acyclic(vertex, edges, visited, parent, nil) do
          {:cycle, _, _} -> {:halt, {visited, parent, false}}
          {:ok, new_visited, new_parent} -> {:cont, {new_visited, new_parent, true}}
        end
      end
    end)
    |> elem(2)
  end

  @doc """
  Checks if the graph contains any cycles.
  """
  @spec is_cyclic?(t()) :: boolean()
  def is_cyclic?(graph), do: not is_acyclic?(graph)

  @spec neighbors(t(), vertex()) :: [vertex()]
  def neighbors(%__MODULE__{edges: edges}, vertex) do
    edges
    |> Map.get(vertex, %{})
    |> Map.keys()
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

  defp build_path(predecessors, target) do
    build_path_recursive(predecessors, target, [target])
  end

  defp build_path_recursive(predecessors, current, path) do
    case Map.get(predecessors, current) do
      nil -> path
      predecessor -> build_path_recursive(predecessors, predecessor, [predecessor | path])
    end
  end

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

  defp bron_kerbosch(r, p, x, graph) do
    if MapSet.size(p) == 0 and MapSet.size(x) == 0 do
      [MapSet.to_list(r)]
    else
      pivot = choose_pivot(p, x, graph)
      excluded_neighbors = get_neighbors(pivot, graph)

      p
      |> MapSet.difference(excluded_neighbors)
      |> MapSet.to_list()
      |> Enum.flat_map(fn v ->
        neighbors = get_neighbors(v, graph)
        new_r = MapSet.put(r, v)
        new_p = MapSet.intersection(p, neighbors)
        new_x = MapSet.intersection(x, neighbors)
        bron_kerbosch(new_r, new_p, new_x, graph)
      end)
    end
  end

  defp get_neighbors(v, %__MODULE__{edges: edges}) do
    edges
    |> Map.get(v, %{})
    |> Map.keys()
    |> MapSet.new()
  end

  defp choose_pivot(p, x, graph) do
    candidates = MapSet.union(p, x)

    if MapSet.size(candidates) == 0 do
      nil
    else
      MapSet.to_list(candidates)
      |> Enum.max_by(fn v ->
        neighbors = get_neighbors(v, graph)
        MapSet.intersection(p, neighbors) |> MapSet.size()
      end)
    end
  end

  defp dfs_acyclic(vertex, edges, visited, parent, prev) do
    new_visited = MapSet.put(visited, vertex)
    new_parent = Map.put(parent, vertex, prev)

    neighbors = Map.get(edges, vertex, %{}) |> Map.keys()

    Enum.reduce_while(neighbors, {:ok, new_visited, new_parent}, fn neighbor, {:ok, vis, par} ->
      cond do
        neighbor == prev ->
          {:cont, {:ok, vis, par}}

        MapSet.member?(vis, neighbor) ->
          {:halt, {:cycle, vis, par}}

        true ->
          case dfs_acyclic(neighbor, edges, vis, par, vertex) do
            {:cycle, new_vis, new_par} -> {:halt, {:cycle, new_vis, new_par}}
            {:ok, new_vis, new_par} -> {:cont, {:ok, new_vis, new_par}}
          end
      end
    end)
  end
end
