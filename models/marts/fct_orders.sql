WITH shipping_data AS (
    SELECT * FROM {{ ref('int_shipping_performance') }}
),

enriched AS (
    SELECT
        -- IDs
        order_item_id,
        order_id,

        -- Time dimensions
        order_at,
        shipped_at,
        DATE_TRUNC('month', order_at)                                   AS order_month,
        DATE_TRUNC('quarter', order_at)                                 AS order_quarter,
        EXTRACT(YEAR FROM order_at)                                     AS order_year,

        -- Dimensions
        order_region,
        order_city,
        market,
        shipping_mode,
        delivery_status,
        order_status,
        order_health,
        customer_segment,
        department_name,
        product_name,

        -- Financial metrics
        ROUND(sales_amount, 2)                                          AS sales_amount,
        ROUND(profit_amount, 2)                                         AS profit_amount,
        ROUND(
            profit_amount / NULLIF(sales_amount, 0) * 100, 2
        )                                                               AS order_margin_pct,
        ROUND(discount_rate * 100, 2)                                   AS discount_rate_pct,
        order_quantity,

        -- Logistics metrics
        actual_shipping_days,
        scheduled_shipping_days,
        shipping_delay_days,
        fulfillment_cycle_days,
        is_late_shipment,
        delay_severity,

        -- Readable label
        CASE
            WHEN is_late_shipment = 1 THEN 'Late'
            ELSE 'On Time'
        END                                                             AS shipment_status_label,

        -- Data quality flag
        CASE
            WHEN shipping_mode = 'First Class'
             AND actual_shipping_days = 2
             AND scheduled_shipping_days = 1
            THEN TRUE ELSE FALSE
        END                                                             AS is_first_class_anomaly

    FROM shipping_data
)

SELECT * FROM enriched