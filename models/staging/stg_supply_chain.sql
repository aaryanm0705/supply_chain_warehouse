-- Grain: one row per order line item (order_item_id).
-- A single order_id can appear multiple times when a customer
-- ordered more than one product. Use order_item_id for row-level
-- uniqueness and order_id for order-level aggregations.

WITH source AS (
    SELECT * FROM {{ source('public', 'raw_supply_chain') }}
),

renamed AS (
    SELECT
        -- IDs
        CAST("Order Item Id" AS INT)                        AS order_item_id,
        CAST("Order Id" AS INT)                             AS order_id,
        CAST("Customer Id" AS INT)                         AS customer_id,
        CAST("Category Id" AS INT)                         AS category_id,

        -- Timestamps
        TO_TIMESTAMP("order date (DateOrders)", 
            'MM/DD/YYYY HH24:MI')                          AS order_at,
        TO_TIMESTAMP("shipping date (DateOrders)", 
            'MM/DD/YYYY HH24:MI')                          AS shipped_at,

        -- Metrics
        CAST("Days for shipping (real)" AS INT)            AS actual_shipping_days,
        CAST("Days for shipment (scheduled)" AS INT)       AS scheduled_shipping_days,
        CAST("Sales" AS DECIMAL(10,2))                     AS sales_amount,
        CAST("Order Profit Per Order" AS DECIMAL(10,2))    AS profit_amount,
        CAST("Order Item Discount Rate" AS DECIMAL(5,4))   AS discount_rate,
        CAST("Order Item Quantity" AS INT)                 AS order_quantity,

        -- Flags
        CAST("Late_delivery_risk" AS INT)                  AS is_late_risk,

        -- Dimensions
        "Delivery Status"                                  AS delivery_status,
        "Order Status"                                     AS order_status,
        "Order Region"                                     AS order_region,
        "Order City"                                       AS order_city,
        "Shipping Mode"                                    AS shipping_mode,
        "Customer Segment"                                 AS customer_segment,
        "Market"                                           AS market,
        "Department Name"                                  AS department_name,
        "Product Name"                                     AS product_name

    FROM source
)

SELECT * FROM renamed