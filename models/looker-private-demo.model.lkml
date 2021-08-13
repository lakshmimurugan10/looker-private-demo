connection: "looker-private-demo"

# include all the views
include: "/views/**/*.view"

datagroup: default_datagroup {
  # sql_trigger: SELECT MAX(id) FROM etl_log;;
  max_cache_age: "1 hour"
}

persist_with: default_datagroup

explore: order_items {
  label: "Ecommerce Demo"
  view_name: order_items
}
