defmodule Giraffe.PriorityQueue do
  @moduledoc """
  A Priority Queue implementation using a list-based heap structure.
  Lower priority values are dequeued first.
  """

  defstruct items: []

  @type t :: %__MODULE__{
          items: list({number(), any()})
        }

  @doc """
  Creates a new empty priority queue
  """
  @spec new() :: t
  def new, do: %__MODULE__{}

  @doc """
  Enqueues an item with a given priority
  """
  def enqueue(%__MODULE__{items: items}, priority, value) do
    %__MODULE__{items: insert({priority, value}, items)}
  end

  @doc """
  Dequeues the item with the lowest priority
  Returns {item, new_queue} or :empty if queue is empty
  """
  def dequeue(%__MODULE__{items: []}), do: :empty

  def dequeue(%__MODULE__{items: [{_priority, value} | rest]}) do
    {value, %__MODULE__{items: rest}}
  end

  @doc """
  Returns the size of the queue
  """
  def size(%__MODULE__{items: items}), do: length(items)

  @doc """
  Checks if the queue is empty
  """
  def empty?(%__MODULE__{items: []}), do: true
  def empty?(%__MODULE__{items: _}), do: false

  # Private helper functions
  defp insert(item, []), do: [item]

  defp insert({priority, _} = item, [{head_priority, _} | _] = items)
       when priority < head_priority do
    [item | items]
  end

  defp insert(item, [head | tail]) do
    [head | insert(item, tail)]
  end

  @doc """
  Returns the highest priority item without removing it from the queue
  Returns {:ok, item} or :empty if queue is empty
  """
  def peek(%__MODULE__{items: []}), do: :empty
  def peek(%__MODULE__{items: [{_priority, value} | _rest]}), do: {:ok, value}

  defimpl Inspect do
    def inspect(%Giraffe.PriorityQueue{items: []}, _), do: "#PriorityQueue<size: 0, queue: []>"

    def inspect(%Giraffe.PriorityQueue{items: list}, opts) do
      items = Enum.map(list, fn {_, item} -> item end)
      count = Enum.count(list)
      doc = Inspect.Algebra.to_doc(items, opts)
      Inspect.Algebra.concat(["#PriorityQueue<size: #{count}, queue: ", doc, ">"])
    end
  end
end
