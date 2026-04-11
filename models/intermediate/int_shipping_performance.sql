WITH staging_data AS (
    SELECT * FROM {{ ref('stg_supply_chain') }}
),

shipping_logic AS (
    SELECT
        *,
        -- 1. Shipping Gap
        actual_shipping_days - scheduled_shipping_days     AS shipping_delay_days,

        -- 2. Binary Late Flag (actual outcome — compare against is_late_risk
        --    for prediction vs reality analysis)
        CASE 
            WHEN actual_shipping_days > scheduled_shipping_days 
            THEN 1 ELSE 0 
        END                                                AS is_late_shipment,

        -- 3. Fulfillment Cycle Time (order placed to physically shipped)
        EXTRACT(DAY FROM shipped_at - order_at)            AS fulfillment_cycle_days,

        -- 4. Delay Severity
        CASE 
            WHEN (actual_shipping_days - scheduled_shipping_days) <= 0 
                THEN 'On-Time/Early'
            WHEN (actual_shipping_days - scheduled_shipping_days) = 1  
                THEN 'Minor Delay'
            WHEN (actual_shipping_days - scheduled_shipping_days) = 2  
                THEN 'Moderate Delay'
            ELSE 'Critical Failure'
        END                                                AS delay_severity,

        -- 5. Order Health Flag (cancellations and fraud are operationally distinct)
        CASE
            WHEN order_status = 'CANCELED'          THEN 'Canceled'
            WHEN order_status = 'SUSPECTED_FRAUD'   THEN 'Fraud'
            WHEN order_status = 'COMPLETE'          THEN 'Complete'
            ELSE 'In Progress'
        END                                                AS order_health

    FROM staging_data
)

SELECT
    -- IDs
    order_item_id,
    order_id,
    customer_id,
    category_id,

    -- Timestamps
    order_at,
    shipped_at,

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
    sales_amount,
    profit_amount,
    discount_rate,
    order_quantity,

    -- Logistics metrics
    actual_shipping_days,
    scheduled_shipping_days,
    shipping_delay_days,
    fulfillment_cycle_days,
    is_late_shipment,
    delay_severity,

    -- Risk flag from source data (predicted risk, compare with is_late_shipment
    -- for prediction accuracy analysis)
    is_late_risk

FROM shipping_logic