defmodule Hefty.Traders do
  import Ecto.Query, only: [from: 2]
  require Logger

  def fetch_naive_trader_settings() do
    from(nts in Hefty.Repo.NaiveTraderSetting,
      order_by: nts.symbol
    )
    |> Hefty.Repo.all()
  end

  def fetch_naive_trader_settings(offset, limit, symbol \\ "") do
    Logger.debug("Fetching naive trader settings for a symbol(#{symbol})")

    from(nts in Hefty.Repo.NaiveTraderSetting,
      order_by: nts.symbol,
      where: like(nts.symbol, ^"%#{String.upcase(symbol)}%"),
      limit: ^limit,
      offset: ^offset
    )
    |> Hefty.Repo.all()
  end

  @spec count_naive_trader_settings(String.t()) :: number()
  def count_naive_trader_settings(symbol \\ "") do
    Logger.debug("Fetching number of naive trader settings for a symbol(#{symbol})")

    from(nts in Hefty.Repo.NaiveTraderSetting,
      select: count("*"),
      where: like(nts.symbol, ^"%#{String.upcase(symbol)}%")
    )
    |> Hefty.Repo.one()
  end

  def update_naive_trader_settings(data) do
    record = Hefty.Repo.get_by!(Hefty.Repo.NaiveTraderSetting, symbol: data["symbol"])

    nts =
      Ecto.Changeset.change(
        record,
        %{
          :budget => data["budget"],
          :buy_down_interval => data["buy_down_interval"],
          :chunks => String.to_integer(data["chunks"]),
          :profit_interval => data["profit_interval"],
          :rebuy_interval => data["rebuy_interval"],
          :retarget_interval => data["retarget_interval"],
          :stop_loss_interval => data["stop_loss_interval"]
        }
      )

    case Hefty.Repo.update(nts) do
      {:ok, struct} ->
        Hefty.Algos.Naive.Leader.update_settings(data["symbol"], struct)
        struct

      {:error, _changeset} ->
        throw("Unable to update " <> data["symbol"] <> " naive trader settings")
    end
  end

  @spec update_status(String.t(), String.t()) :: :ok
  def update_status(symbol, status) when is_binary(symbol) and is_binary(status) do
    Hefty.Algos.Naive.Server.update_status(symbol, status)
  end
end
