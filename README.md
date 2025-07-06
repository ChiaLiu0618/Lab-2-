# IC Lab – Lab02: Coordinate Calculation (CC)

**NCTU-EE IC LAB**  
**Fall 2023**

## Introduction

This lab focuses on designing a circuit to handle geometric operations on coordinates with three modes:
1. **Trapezoid Rendering**
2. **Circle-Line Relationship Detection**
3. **Quadrilateral Area Calculation**

The goal is to correctly process coordinates, produce valid outputs, and meet synthesis and timing constraints.

---

## Modes

### 1️⃣ Trapezoid Rendering (Mode 0)
- When `in_valid` is high, you receive four sets of coordinates:  
  `(xul, yu)`, `(xur, yu)`, `(xdl, yd)`, `(xdr, yd)`.
- The circuit must output all covered square coordinates (bottom-left corner).
- Output order: left to right, bottom to top.
- Example:
  - `(xul, yu)` = (02,0C), `(xur, yu)` = (09,0C), `(xdl, yd)` = (00,00), `(xdr, yd)` = (10,00)

---

### 2️⃣ Circle-Line Relationship (Mode 1)
- `in_valid` sends:
  - Two points defining the line `(a1,a2)` and `(b1,b2)`
  - Circle center `(c1,c2)` and a point on the circle `(d1,d2)`
- Output (`{xo, yo}`):
  - `{00,00}`: Non-intersecting
  - `{00,01}`: Intersecting
  - `{00,02}`: Tangent

---

### 3️⃣ Area Calculation (Mode 2)
- `in_valid` sends four sets of coordinates: `(a1,a2)`, `(b1,b2)`, `(c1,c2)`, `(d1,d2)`.
- Compute the area of the quadrilateral.
- If the result has decimals, round down.

---

## I/O Specification

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| `clk` | input | 1 | Clock |
| `rst_n` | input | 1 | Active-low async reset |
| `mode` | input | 2 | 0: trapezoid, 1: circle-line, 2: area |
| `in_valid` | input | 1 | High when input is valid |
| `xi` | input | 8 | X coordinate (two's complement) |
| `yi` | input | 8 | Y coordinate (two's complement) |
| `out_valid` | output | 1 | High when output is valid |
| `xo` | output | 8 | X output / area MSB / set to 0 for mode 1 |
| `yo` | output | 8 | Y output / area LSB / relation code for mode 1 |

---

## Specifications

1. **Top Module Name:** `CC.v`
2. **Architecture:** Asynchronous active-low reset only.
3. **Clock Period:** Fixed at 12 ns.
4. Next input group: arrives 2–5 cycles after `out_valid` falls.
5. **No latches allowed:** (`grep "Latch" 02_SYN/syn.log`)
6. Synthesis reports:
   - `CC.area` and `CC.timing` in `Report/`
   - Slack must be non-negative (`MET`)
7. Gate-level sim must have **no timing violations**.
8. **Latency:** ≤ 100 cycles (from `in_valid` falling to `out_valid` rising).
9. Forbidden names: `error`, `latch`, `congratulation`.
10. `out_valid` must not overlap with `in_valid`.

---

## Grading

| Component | Weight |
|-----------|--------|
| RTL and Gate-level correctness | 70% |
| Performance (Area × Execution Cycle) | 30% |

- 2nd demo submission: 30% penalty.
- Plagiarism: 0 points.
- Naming violations: −5 points.

---

## Submission Deadlines

- **1st Demo:** 2023/10/02 (Mon) 12:00 PM
- **2nd Demo:** 2023/10/04 (Wed) 12:00 PM

---

## Commands

| Step | Command |
|------|---------|
| RTL Sim | `./01_run_vcs_rtl` |
| Synthesis | `./01_run_dc_shell` |
| Gate-level Sim | `./01_run_vcs_gate` |
| Pack Submission | `./00_tar` |
| Submit | `./01_submit` |
| Check Submission | `./02_check` |

---

## Hints

- Use Surveyor’s Formula for area.
- For distance: P(x₀,y₀) to L: `ax + by + c = 0`
- Prefer behavioral modeling.
- Keep latency within constraints.

---

## Note

Always check:
- `Report/CC.area` and `Report/CC.timing`  
- Ensure `MET` and no `Latch`.

Good luck!
