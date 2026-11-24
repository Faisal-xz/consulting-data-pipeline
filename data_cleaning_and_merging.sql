USE namaa_consulting_db;

-- ============================================================================
-- PHASE 1: DATA QUALITY AUDIT (فحص واكتشاف مشاكل البيانات الخام)
-- ============================================================================

-- 1. اكتشاف الطلبات المكررة في نظام ERP
SELECT order_id, COUNT(*) AS duplicate_count
FROM raw_erp_orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- 2. اكتشاف السجلات اليتيمة (طلبات لعملاء غير موجودين في نظام CRM)
SELECT o.order_id, o.customer_id
FROM raw_erp_orders o
LEFT JOIN raw_crm_customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- 3. فحص القيم الفارغة (NULL) في المدن والمبالغ المالية
SELECT 
    SUM(CASE WHEN city IS NULL OR TRIM(city) = '' THEN 1 ELSE 0 END) AS missing_cities
FROM raw_erp_orders;

SELECT 
    SUM(CASE WHEN amount_sar IS NULL THEN 1 ELSE 0 END) AS missing_amounts
FROM raw_finance_payments;


-- ============================================================================
-- PHASE 2: DATA CLEANING & STANDARDIZATION (تنظيف وتوحيد البيانات)
-- ============================================================================

-- 1. تنظيف جدول الطلبات: إزالة التكرار، توحيد صيغ التواريخ، وتنظيف النصوص
DROP TABLE IF EXISTS clean_erp_orders;
CREATE TABLE clean_erp_orders AS
WITH DeduplicatedOrders AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_date) AS rn
    FROM raw_erp_orders
)
SELECT 
    TRIM(order_id) AS order_id,
    -- تحويل صيغ التواريخ المختلفة إلى صيغة قياسية واحدة (YYYY-MM-DD)
    CASE 
        WHEN order_date LIKE '%/%/%' AND LENGTH(SUBSTRING_INDEX(order_date, '/', 1)) = 2 
            THEN STR_TO_DATE(order_date, '%d/%m/%Y')
        WHEN order_date LIKE '%/%/%' AND LENGTH(SUBSTRING_INDEX(order_date, '/', 1)) = 4 
            THEN STR_TO_DATE(order_date, '%Y/%m/%d')
        ELSE STR_TO_DATE(order_date, '%Y-%m-%d')
    END AS order_date,
    TRIM(customer_id) AS customer_id,
    TRIM(service_type) AS service_type,
    -- توحيد حالة الأحرف للمدن وتعويض القيم المفقودة بـ Unknown
    COALESCE(
        CONCAT(UPPER(LEFT(TRIM(city), 1)), LOWER(SUBSTRING(TRIM(city), 2))),
        'Unknown'
    ) AS city
FROM DeduplicatedOrders
WHERE rn = 1;

-- 2. تنظيف جدول المدفوعات: توحيد حالة الدفع وتوثيق المبالغ المفقودة
DROP TABLE IF EXISTS clean_finance_payments;
CREATE TABLE clean_finance_payments AS
SELECT 
    TRIM(payment_id) AS payment_id,
    TRIM(order_id) AS order_id,
    COALESCE(amount_sar, 0) AS amount_sar,
    CASE WHEN amount_sar IS NULL THEN 'Missing Amount' ELSE 'Verified' END AS amount_audit_flag,
    CONCAT(UPPER(LEFT(TRIM(payment_status), 1)), LOWER(SUBSTRING(TRIM(payment_status), 2))) AS payment_status
FROM raw_finance_payments;


-- ============================================================================
-- PHASE 3: DATA MERGING & FINAL VIEW FOR REPORTING (دمج الأنظمة الثلاثة)
-- ============================================================================

DROP TABLE IF EXISTS final_consulting_report;
CREATE TABLE final_consulting_report AS
SELECT 
    o.order_id,
    o.order_date,
    YEAR(o.order_date) AS order_year,
    MONTHNAME(o.order_date) AS order_month,
    MONTH(o.order_date) AS month_num,
    o.customer_id,
    COALESCE(c.client_name, 'Unregistered Client (Audit Needed)') AS client_name,
    COALESCE(c.sector, 'Unclassified') AS sector,
    COALESCE(c.account_manager, 'Unassigned') AS account_manager,
    o.service_type,
    o.city,
    p.payment_id,
    p.amount_sar,
    p.amount_audit_flag,
    p.payment_status
FROM clean_erp_orders o
LEFT JOIN raw_crm_customers c ON o.customer_id = c.customer_id
LEFT JOIN clean_finance_payments p ON o.order_id = p.order_id;

-- التحقق النهائي من الجدول المدمج النظيف
SELECT COUNT(*) AS final_clean_rows FROM final_consulting_report;
SELECT * FROM final_consulting_report LIMIT 10;
