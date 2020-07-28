defmodule Coda.Resources.BlockProducer do
  @moduledoc "BlockProducer resource definition."

  use Architecture.Resource

  defresource(Coda.Resources.CodaNode,
    class: String.t(),
    id: pos_integer(),
    win_rate: float()
  )

  @spec build(String.t(), pos_integer(), float()) :: t()
  def build(class, id, win_rate) do
    %__MODULE__{
      name: "#{class}-block-producer-#{id}",
      class: class,
      id: id,
      win_rate: win_rate
    }
  end

  @impl true
  def global_filter do
    filter(do: labels["k8s-pod/role"] == "block-producer")
  end

  @impl true
  def local_filter(_), do: nil
end
