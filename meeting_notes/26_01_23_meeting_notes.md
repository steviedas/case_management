# Case Management System – Full Meeting Notes  
**Date:** 23 January 2026  
**Attendees:** Joe, Olivia, Tristan (+ engineering team references)  
**Context:** Review of current Case Management tool functionality, gaps, and required enhancements from an end-user operational perspective.

---

## 1. Overview

The session focused on how the Case Management system is expected to be used:

- **Daily / weekly engineering analysis**
- **Customer-facing review meetings**
- **Reducing alert noise**
- **Automating case creation**
- **Improving traceability between alerts, cases, and maintenance actions**
- **Introducing fleet-level monitoring views**

The objective is to move away from static weekly reports and instead use the platform as the **single operational source of truth**.

---

## 2. Intended User Workflow

### Daily / Weekly Analyst Usage

1. Analyst filters fleet by:
   - TOC (e.g. CrossCountry)
   - Class
   - Unit

2. Analyst views:
   - All open and closed cases for the selected fleet or unit
   - Associated alerts
   - System-level fault patterns

3. Analyst performs:
   - Fault investigation
   - Case creation or validation
   - Linking alerts and work orders
   - Recording diagnostic notes

---

## 3. Case List Improvements

### Required Enhancements

- Display **date created** and **date last updated** on each case
  - Allows engineers to judge relevance of historic cases
  - A case completed 4 weeks ago is useful context
  - A case from months ago is not

- Improve filtering usability:
  - Ability to filter by **status** directly at the top of the screen
  - Avoid reliance on deep filter menus for daily use

---

## 4. Alerts Usage & Noise Reduction

### Current Issue

- High volume of informational alerts
- Engineers still need to see alerts, but **not all should raise cases**

### Key Distinction

#### Informational Alerts
Examples:
- Low Boost Pressure
- Very Low Boost Pressure

These:
- Do **not** directly trigger cases
- Create excessive noise
- Should be removed from the mirror

#### Actionable Alerts
Cases should be raised only when **defined thresholds** are breached.

---

## 5. Proposed Case Logic

### Concept of “Proposed Cases”

Cases should be:

- Automatically generated
- Clearly marked as **Proposed**
- Awaiting engineer validation

#### Example:

> Two “Engine Failed to Start” alerts within one week  
→ Automatically create **Proposed Case**

### Benefits

- Analyst does not need to manually raise every case
- Time is focused only on meaningful faults
- Mirrors existing Paradigm Insight workflow

---

## 6. Proposed Case Behaviour

### Visual Indicators

- **Proposed Case:** Yellow highlight
- **Confirmed / Acknowledged Case:** Red highlight
- **Completed / Rejected:** No highlight

### Behaviour Summary

- Proposed cases appear automatically
- Engineer can:
  - Accept the case
  - Reject the case with reason

---

## 7. Case Rejection Requirements

When rejecting a proposed case:

- A **mandatory rejection reason** must be recorded

Example reasons:
- False positive
- Known instrumentation issue
- Under investigation externally

This requires:
- New rejection reason field
- Persistent storage
- Visibility in case history

---

## 8. Alert–Case Linking

### Required Behaviour

- Alerts responsible for proposing a case must be:
  - Automatically linked
  - Visible within the case

Engineers must be able to:

- View triggering alerts
- Inspect alert trace signals
- Validate fault legitimacy without leaving the system

This removes dependency on Paradigm Insight for investigation.

---

## 9. Case Creation Improvements

### Auto-Population

When creating a case:

- Unit
- Vehicle
- Contextual filters

Should automatically populate from the current selection.

---

### Editing Limitations Identified

Current issues:

- Unit cannot be edited after creation
- Vehicle cannot be edited
- Missing unit prevents case appearing under filters

These behaviours must be corrected.

---

## 10. Case Records & Structure

### Case Description vs Initial Record

Clarified behaviour:

- **Description**
  - Acts as a subheading or summary

- **Records**
  - Chronological operational log
  - Used for diagnostics, meetings, updates

This structure was agreed as appropriate.

---

## 11. Case Close-Out Requirements

When completing a case, the system must support:

### Mandatory Close-Out Data

- Delay prevented
- Labour hours

### Additional Required Fields

- **Final Record**
  - Summary of outcome
  - Engineering conclusion

- **Root Cause Code**
  - Required on completion
  - Enables reporting and trend analysis

---

## 12. System, Symptom & Code Structure

### Current Limitation

Cases are only associated to high-level systems.

### Required Enhancement

Introduce a **hierarchical code structure**:

- System  
  - Symptom codes beneath system  

Example:

- Engine
  - Diesel engine not starting
  - Diesel engine low power
  - Diesel engine shutdown

This enables:

- More granular filtering
- Better fleet trend analysis
- Clear root-cause reporting

Suggested approach:
- New `dim_code` table
- Codes linked to cases
- Root code selected at close-out

---

## 13. Case Priorities

Priority wording should be operationally actionable:

Proposed list:

- Attend at next exam
- Attend at next depot visit
- As soon as possible

Avoid priorities implying authority beyond engineering scope (e.g. “Before release to service”).

---

## 14. Work Orders & RFS Handling

### Clarification

- RFS = Third-party maintenance
- Should be treated identically to work orders

Therefore:

- RFS should not appear as a separate case section
- Should live within the existing **work orders** area

---

## 15. Linking Additional Alerts

Engineers may need to:

- Manually add alerts to a case
- Create a case manually if automated logic does not detect it

Alert linking UI should:

- Respect current unit and vehicle filters
- Only show relevant cases
- Prevent cross-unit confusion

---

## 16. UI & Usability Enhancements

### Modal & Trace View

- Signal trace window should be wider
- Preferably responsive to screen size
- Particularly important on laptop screens

---

## 17. Customer Review Workflow

During customer meetings:

- Engineers will no longer issue weekly PDF reports
- Customers will be provided access to the platform

Workflow:

1. Review each unit
2. Walk through open cases
3. Add meeting records
4. Link work orders
5. Capture updates live

This requires:
- Stable case history
- Clear traceability
- Clean UI presentation

---

## 18. Fleet-Level Monitoring Tabs

Three dedicated fleet views are required:

---

### 18.1 Boost Pressure – Fleet View

**Purpose:** Track degradation trends rather than instantaneous faults.

#### Data Characteristics

- Weekly or daily rolling average
- Calculated under conditions:
  - Notch 7
  - Above 1700 RPM

#### Thresholds

- < 2500 → Yellow
- < 2400 → Amber
- < 2300 → Red

#### Table View

| Unit | Vehicle | Avg Boost Pressure | Latest Record |

Each breach automatically represents a case.

#### Graph View

- Fleet-wide daily average
- Individual vehicle trends
- Ability to drill down from fleet → vehicle

Future enhancement:
- Annotate turbo cleans and raft changes

---

### 18.2 Air Standup (Leaks)

Handled exclusively at **unit level**.

#### Metrics

- Air standup passes
- Air standup failures
- Failure rate

#### Case Trigger

- Failure rate > 75% over previous week

No individual alert mirroring required.

---

### 18.3 Coolant Temperature Monitoring

Distinct from standard RCM alerts.

#### Event Definition

- Coolant temperature > 88°C
- Sustained for ≥ 45 seconds

#### Trigger Rule

- Three or more events within a rolling 24-hour window

#### Fleet Table

| Unit | Vehicle | First Triggered | Last Triggered | Days Triggered |

Purpose:
- Track persistence across time
- Identify chronic issues

All original RCM coolant alerts must still remain visible.

---

## 19. Summary of Key Outcomes

- Introduce **proposed case automation**
- Reduce alert noise significantly
- Improve traceability from alert → case → work order
- Enable fleet-level performance monitoring
- Support customer-facing operational reviews
- Replace manual weekly reporting with live system usage

---

## 20. Next Steps

- Create Jira cards for:
  - API changes
  - Database schema updates
  - Case logic
  - Fleet tiles
  - UI improvements

- Confirm thresholds and calculations
- Align mirror logic with fleet-level views
- Deliver incremental improvements in upcoming releases

---
