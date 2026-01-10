# Star Schema Specification
**Source:** tested\proposed_star_schema.png
**Date:** 2026-01-10

---

## Dimension Tables

### 1. dim_toc
**Schema:**
- `toc_id` - INT (PK)
- `toc_name` - VARCHAR

**Relationships:**
- Referenced by: fact_cases.toc_id

---

### 2. dim_class
**Schema:**
- `class_id` - INT (PK)
- `class_name` - VARCHAR

**Relationships:**
- Referenced by: fact_cases.class_id

---

### 3. dim_status
**Schema:**
- `status_id` - INT (PK)
- `status_name` - VARCHAR

**Relationships:**
- Referenced by: fact_cases.status_id

---

### 4. dim_depot
**Schema:**
- `depot_id` - INT (PK)
- `depot_name` - VARCHAR

**Relationships:**
- Referenced by: fact_cases.depot_id

---

### 5. dim_priority
**Schema:**
- `priority_id` - INT (PK)
- `priority_name` - VARCHAR

**Relationships:**
- Referenced by: fact_cases.priority_id

---

### 6. dim_system
**Schema:**
- `system_id` - INT (PK)
- `system_name` - VARCHAR

**Relationships:**
- Referenced by: fact_cases.system_id

---

### 7. dim_alert_status
**Schema:**
- `alert_status_id` - INT (PK)
- `alert_status_name` - VARCHAR

**Relationships:**
- Referenced by: fact_alert.status_id

---

### 8. dim_delphi_unit
**Schema:**
- `unit_id` - INT (PK)
- `unit` - VARCHAR

**Relationships:**
- Referenced by: dim_vehicle.unit_id, case_unit_unit_id

---

### 9. dim_vehicle
**Schema:**
- `vehicle_id` - INT (PK)
- `vehicle` - VARCHAR
- `unit_id` - INT (FK)

**Relationships:**
- References: dim_delphi_unit.unit_id (via unit_id)
- Referenced by: fact_cases.vehicle_id, fact_alert.vehicle_id

---

## Fact Tables

### 10. fact_interventions
**Schema:**
- `toc_id` - INT
- `class_id` - INT
- `depot_id` - INT
- `unit_id` - INT
- `vehicle` - VARCHAR (???)
- `date` - DATE
- `intervention_report` - VARCHAR
- `intervention_action` - VARCHAR
- `a_root_code_display` - VARCHAR
- `a_root_code_display_desc` - VARCHAR
- `intervention_type` - VARCHAR
- `intervention_key` - VARCHAR
- `railway_period` - VARCHAR (???)
- `period_sort_id` - INT
- `period_start_dt` - DATE
- `fleet_name` - VARCHAR (???)
- `location` - VARCHAR
- `porterbrook_asset` - BIT
- `is_rh` - BIT
- `is_verified` - BIT
- `master_intervention_key` - VARCHAR
- `count_full_cancellations` - INT

**Relationships:**
- Referenced by: case_intervention.intervention_id

---

### 11. fact_cases
**Schema:**
- `id` - INT (PK)
- `priority_id` - INT (FK)
- `status_id` - INT (FK)
- `rfs` - VARCHAR
- `title` - VARCHAR
- `description` - VARCHAR
- `system_id` - INT (FK)
- `linked_work_orders` - VARCHAR
- `created_at` - DATETIME2
- `updated_by` - DATETIME2
- `toc_id` - INT (FK NULL)
- `class_id` - INT (FK NULL)
- `depot_id` - INT (FK NULL)
- `vehicle_id` - INT (FK NULL)

**Relationships:**
- References: dim_priority.priority_id (via priority_id)
- References: dim_status.status_id (via status_id)
- References: dim_system.system_id (via system_id)
- References: dim_toc.toc_id (via toc_id)
- References: dim_class.class_id (via class_id)
- References: dim_depot.depot_id (via depot_id)
- References: dim_vehicle.vehicle_id (via vehicle_id)
- Referenced by: fact_records.case_id, case_intervention.case_id, case_alert.case_id

---

### 12. fact_alert
**Schema:**
- `id` - INT (PK)
- `title` - VARCHAR
- `alert_timestamp` - DATETIME2
- `status_id` - INT (FK)
- `date_created` - DATETIME2
- `date_reviewed` - DATETIME2
- `reviewed_by` - VARCHAR
- `rejection_reason` - VARCHAR
- `vehicle_id` - INT (FK)
- `trace_ref_id` - INT (FK NULL)
- `alert_source` - VARCHAR

**Relationships:**
- References: dim_alert_status.alert_status_id (via status_id)
- References: dim_vehicle.vehicle_id (via vehicle_id)
- References: fact_alert_trace_reference.id (via trace_ref_id)
- Referenced by: case_alert.ins_alt_id

---

### 13. fact_records
**Schema:**
- `id` - INT (PK)
- `created_at` - DATE
- `updated_at` - DATE
- `record` - VARCHAR
- `case_id` - INT (FK)
- `author` - VARCHAR
- `record_type` - VARCHAR

**Relationships:**
- References: fact_cases.id (via case_id)

---

### 14. fact_alert_trace_reference
**Schema:**
- `id` - INT (PK)
- `storage_path` - VARCHAR
- `file_format` - VARCHAR
- `date_created` - DATETIME2
- `trace_start_time` - DATETIME2
- `trace_end_time` - DATETIME2
- `signal_count` - INT
- `row_count` - INT

**Relationships:**
- Referenced by: fact_alert.trace_ref_id

---

## Bridge Tables

### 15. case_intervention
**Schema:**
- `case_id` - INT (FK)
- `intervention_id` - INT (FK)

**Relationships:**
- References: fact_cases.id (via case_id)
- References: fact_interventions (via master_intervention_key)

---

### 16. case_alert
**Schema:**
- `case_id` - INT (FK)
- `ins_alt_id` - INT (FK)
- `date_assigned` - DATETIME2
- `assigned_by` - VARCHAR
- `assigned_notes` - VARCHAR
- `alert_source` - VARCHAR

**Relationships:**
- References: fact_cases.id (via case_id)
- References: fact_alert.id (via ins_alt_id)

---
