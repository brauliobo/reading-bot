# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table :subscribers do
      add_column :messages, :jsonb, default: [].to_json
    end
  end
end
