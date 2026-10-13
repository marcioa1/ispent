defmodule Ispent.Repo.Migrations.ChangeExpenseDatetimeToUtcDatetime do
  use Ecto.Migration

  def up do
    execute("""
    ALTER TABLE expenses
    ALTER COLUMN datetime TYPE timestamp(0) without time zone
    USING ((datetime::timestamp AT TIME ZONE 'America/Sao_Paulo') AT TIME ZONE 'UTC')
    """)
  end

  def down do
    execute("""
    ALTER TABLE expenses
    ALTER COLUMN datetime TYPE date
    USING ((datetime AT TIME ZONE 'UTC') AT TIME ZONE 'America/Sao_Paulo')::date
    """)
  end
end
