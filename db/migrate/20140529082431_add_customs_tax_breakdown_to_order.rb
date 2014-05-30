class AddCustomsTaxBreakdownToOrder < ActiveRecord::Migration
  def change
    add_column :spree_orders, :gwansae, :decimal, :precision => 10, :scale => 2, :default => 0.0
    add_column :spree_orders, :bugasae, :decimal, :precision => 10, :scale => 2, :default => 0.0
  end
end
