defmodule Giraffe.PriorityQueueTest do
  use ExUnit.Case
  doctest Giraffe.PriorityQueue

  alias Giraffe.PriorityQueue, as: PriorityQueue

  describe "new/0" do
    test "creates an empty priority queue" do
      queue = PriorityQueue.new()
      assert queue.items == []
    end
  end

  describe "enqueue/3" do
    test "adds items in priority order" do
      queue =
        PriorityQueue.new()
        |> PriorityQueue.enqueue(3, "low")
        |> PriorityQueue.enqueue(1, "high")
        |> PriorityQueue.enqueue(2, "medium")

      assert queue.items == [{1, "high"}, {2, "medium"}, {3, "low"}]
    end

    test "handles items with same priority" do
      queue =
        PriorityQueue.new()
        |> PriorityQueue.enqueue(1, "first")
        |> PriorityQueue.enqueue(1, "second")

      assert length(queue.items) == 2
    end
  end

  describe "dequeue/1" do
    test "removes and returns highest priority item" do
      queue =
        PriorityQueue.new()
        |> PriorityQueue.enqueue(3, "low")
        |> PriorityQueue.enqueue(1, "high")
        |> PriorityQueue.enqueue(2, "medium")

      {item, new_queue} = PriorityQueue.dequeue(queue)
      assert item == "high"
      {item2, _} = PriorityQueue.dequeue(new_queue)
      assert item2 == "medium"
    end

    test "returns :empty for empty queue" do
      assert PriorityQueue.dequeue(PriorityQueue.new()) == :empty
    end
  end

  describe "size/1" do
    test "returns correct size" do
      queue = PriorityQueue.new()
      assert PriorityQueue.size(queue) == 0

      queue =
        queue
        |> PriorityQueue.enqueue(1, "a")
        |> PriorityQueue.enqueue(2, "b")

      assert PriorityQueue.size(queue) == 2
    end
  end

  describe "empty?/1" do
    test "returns true for empty queue" do
      assert PriorityQueue.empty?(PriorityQueue.new())
    end

    test "returns false for non-empty queue" do
      queue =
        PriorityQueue.new()
        |> PriorityQueue.enqueue(1, "item")

      refute PriorityQueue.empty?(queue)
    end
  end

  describe "integration tests" do
    test "handles multiple operations" do
      queue = PriorityQueue.new()
      assert PriorityQueue.empty?(queue)

      queue =
        queue
        |> PriorityQueue.enqueue(3, "low")
        |> PriorityQueue.enqueue(1, "high")
        |> PriorityQueue.enqueue(2, "medium")

      assert PriorityQueue.size(queue) == 3

      {item1, queue} = PriorityQueue.dequeue(queue)
      assert item1 == "high"

      {item2, queue} = PriorityQueue.dequeue(queue)
      assert item2 == "medium"

      {item3, queue} = PriorityQueue.dequeue(queue)
      assert item3 == "low"

      assert PriorityQueue.empty?(queue)
      assert PriorityQueue.dequeue(queue) == :empty
    end
  end
end
