#### Multi-Department Operations & Data Quality Pipeline (MySQL, Excel, Power BI)

#### Project Overview

This project simulates a real-world business data workflow where fragmented datasets arrive from multiple internal systems (**ERP Orders**, **Finance Payments**, and **CRM Client Records**) with inconsistent formats, duplicate entries, and missing values. The objective is to audit data quality, clean and consolidate all records using **MySQL**, document anomalies, and deliver an executive **Power BI** dashboard to support business decision-making. 

#### Tools & Technologies

* **MySQL:** Data quality auditing, deduplication (ROW_NUMBER), date/text standardization (STR_TO_DATE, TRIM), and multi-table merging (LEFT JOIN).
* **Microsoft Excel:** Data Quality Log documentation and reconciliation tracking.
* **Power BI:** Interactive KPI tracking, monthly revenue trend analysis, and service-line performance reporting.

#### Key Data Quality Issues Resolved

1. **Duplicate Records:** Identified and removed **15 duplicate order entries** from the ERP export using CTEs and window functions.
2. **Orphan Records:** Detected **15 orders** linked to unregistered client IDs (C99); retained financial records for accuracy while flagging them as Audit Needed.
3. **Date & Text Standardization:** Unified mixed date formats (DD/MM/YYYY, YYYY/MM/DD) into ISO format (YYYY-MM-DD) and standardized inconsistent city/status casing.
4. **Missing Values:** Handled NULL payment amounts by assigning an explicit Missing Amount audit flag rather than silently dropping records.
   
## Dashboard Preview

<img width="1197" height="672" alt="dashboard_overview" src="https://github.com/user-attachments/assets/a04d3cb7-1b19-4ebb-a67c-d264269a6252" />


#### Repository Structure

* data_cleaning_and_merging.sql — Complete SQL script for data auditing, cleaning, and table consolidation.
* Data_Quality_Log.xlsx — Structured documentation of discovered data issues and applied business rules.
* final_consulting_report.csv — Final consolidated dataset (500 clean records) used for BI reporting.
* Namaa_Consulting_Dashboard.pbix — Power BI source file.
* dashboard_overview.png — Screenshot of the final interactive dashboard.
