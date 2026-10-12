defmodule Ispent.Expense do
  use Ecto.Schema
  import Ecto.Changeset

  schema "expenses" do
    field :details, :string
    field :value, :float
    field :datetime, :date
    field :latitude, :float
    field :longitude, :float
    field :location_name, :string
    field :extraordinary, :boolean, default: false

    belongs_to :category, Ispent.Category

    timestamps()
  end

  def changeset(expense, attrs) do
    expense
    |> cast(attrs, [
      :category_id,
      :details,
      :value,
      :datetime,
      :latitude,
      :longitude,
      :location_name,
      :extraordinary
    ])
    |> validate_required([:category_id, :details, :value, :datetime])
    |> foreign_key_constraint(:category_id)
  end
end
