WITH shipping_data AS (
    SELECT * FROM {{ ref('int_shipping_performance') }}
),

final_summary AS (
    SELECT
        order_region,
        shipping_mode,

        -- Business Volume
        COUNT(DISTINCT order_id)                                        AS total_orders,
        SUM(order_quantity)                                             AS total_units_sold,

        -- Financial Health
        ROUND(SUM(sales_amount), 2)                                     AS total_sales,
        ROUND(SUM(profit_amount), 2)                                    AS total_profit,
        ROUND(
            (SUM(profit_amount) / NULLIF(SUM(sales_amount), 0)) * 100,
        2)                                                              AS portfolio_margin_pct,
        ROUND(AVG(discount_rate) * 100, 2)                              AS avg_discount_rate_pct,

        -- Logistics Performance
        ROUND(AVG(shipping_delay_days), 2)                              AS avg_shipping_delay_days,
        ROUND(AVG(is_late_shipment) * 100, 2)                           AS late_delivery_rate_pct,
        ROUND(AVG(fulfillment_cycle_days), 2)                           AS avg_fulfillment_cycle_days,
        COUNT(CASE WHEN is_late_shipment = 1 THEN 1 END)                AS total_late_orders,
        COUNT(CASE WHEN is_late_shipment = 0 THEN 1 END)                AS total_ontime_orders,

        -- Scheduled vs Actual
        ROUND(AVG(scheduled_shipping_days), 2)                          AS avg_scheduled_days,
        ROUND(AVG(actual_shipping_days), 2)                             AS avg_actual_days,

        -- Order Health (using order_health from int_shipping_performance)
        ROUND(AVG(
            CASE WHEN order_health = 'Canceled' THEN 1 ELSE 0 END
        ) * 100, 2)                                                     AS cancellation_rate_pct,
        ROUND(AVG(
            CASE WHEN order_health = 'Fraud' THEN 1 ELSE 0 END
        ) * 100, 2)                                                     AS fraud_rate_pct,

        -- Data Quality Flag
        CASE
            WHEN ROUND(AVG(is_late_shipment) * 100, 2) = 100
            THEN TRUE ELSE FALSE
        END                                                             AS is_anomalous_late_rate

    FROM shipping_data
    GROUP BY 1, 2
)

SELECT * FROM final_summary
ORDER BY total_sales DESC