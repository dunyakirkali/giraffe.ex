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
  @spec add_edge(t(), vertex(), vertex(), weight()) :: t()
  def add_edge(graph, v1, v2, weight \\ 1) do
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
  Returns a list of all edges in the graph.
  Each edge is represented as a tuple {from, to, weight}.
  """
  @spec edges(t()) :: [edge()]
  def edges(graph) do
    graph.edges
    |> Enum.flat_map(fn {v1, edges} ->
      Enum.map(edges, fn {v2, weight} ->
        if v1 <= v2, do: {v1, v2, weight}, else: {v2, v1, weight}
      end)
    end)
    |> Enum.uniq()
  end

  @doc """
  Finds the shortest path between two vertices using Dijkstra's algorithm.
  Returns {:ok, path, total_weight} if a path exists, :no_path otherwise.
  """
  @spec get_shortest_path(t(), vertex(), vertex()) :: {:ok, [vertex()], weight()} | :no_path
  def get_shortest_path(graph, start, finish) do
    case dijkstra(graph, start, finish) do
      {:ok, distances, predecessors} ->
        case Map.get(distances, finish) do
          nil ->
            :no_path

          :infinity ->
            :no_path

          total_weight ->
            path = build_path(predecessors, finish)
            {:ok, path, total_weight}
        end

      :no_path ->
        :no_path
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

  defp dijkstra(%__MODULE__{edges: edges, vertices: vertices}, start, finish) do
    if not MapSet.member?(vertices, start) or not MapSet.member?(vertices, finish) do
      :no_path
    else
      distances =
        MapSet.to_list(vertices)
        |> Map.new(fn vertex ->
          if vertex == start, do: {vertex, 0}, else: {vertex, :infinity}
        end)

      dijkstra_traverse(edges, MapSet.to_list(vertices) |> MapSet.new(), distances, %{})
    end
  end

  defp dijkstra_traverse(edges, unvisited, distances, predecessors)
       when map_size(distances) > 0 do
    case find_min_distance_vertex(unvisited, distances) do
      nil ->
        {:ok, distances, predecessors}

      current ->
        if Map.get(distances, current) == :infinity do
          :no_path
        else
          neighbors = Map.get(edges, current, %{})

          {new_distances, new_predecessors} =
            update_distances(neighbors, current, distances, predecessors)

          dijkstra_traverse(
            edges,
            MapSet.delete(unvisited, current),
            new_distances,
            new_predecessors
          )
        end
    end
  end

  defp find_min_distance_vertex(unvisited, distances) do
    Enum.min_by(
      MapSet.to_list(unvisited),
      fn vertex -> Map.get(distances, vertex, :infinity) end,
      &<=/2,
      fn -> nil end
    )
  end

  defp update_distances(neighbors, current, distances, predecessors) do
    current_distance = Map.get(distances, current)

    Enum.reduce(neighbors, {distances, predecessors}, fn {neighbor, weight},
                                                         {dist_acc, pred_acc} ->
      case Map.get(dist_acc, neighbor) do
        nil ->
          {dist_acc, pred_acc}

        neighbor_distance ->
          potential_distance = current_distance + weight

          if neighbor_distance == :infinity or potential_distance < neighbor_distance do
            {
              Map.put(dist_acc, neighbor, potential_distance),
              Map.put(pred_acc, neighbor, current)
            }
          else
            {dist_acc, pred_acc}
          end
      end
    end)
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
