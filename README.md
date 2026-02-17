# AutoPump - GTNH Space Elevator Fluid Management

A Lua script for automating fluid extraction using the Space Elevator system in GregTech: New Horizons. Parts of this README has been written by AI. Please inform me if anything is erroneous.

## Overview

AutoPump manages multiple Project Module Pump tiers across 7 planets, automatically adjusting pump targets based on ME network fluid levels. The script monitors fluid inventory, prioritizes critical fluids, and dynamically allocates pumps to maintain optimal storage levels across 40 different fluid types.

## Features

### Dynamic Target Management
The script calculates fluid targets dynamically rather than using fixed values. Each iteration:
- Computes the median fluid amount across all tracked fluids
- Sets a global target based on the median plus a configurable offset
- Ensures targets never exceed maximum storage capacity (99% of singularity cell size)

This approach automatically adapts to network conditions, preventing over-pumping while maintaining balanced fluid levels.

### Priority-Based Pumping
Fluids are assigned priority levels (0-3), with higher priority fluids pumped first when multiple fluids fall below target. Within the same priority tier, the script favors fluids with the lowest fill ratio, ensuring the most depleted resources receive attention.

### Multi-Tier Pump Support
Automatically detects and utilizes three pump tiers:
- **Tier 1**: 1 thread, 4x rate multiplier
- **Tier 2**: 4 threads, 16x rate multiplier  
- **Tier 3**: 4 threads, 256x rate multiplier

Pumps are assigned in priority order, with higher-tier pumps allocated to critical tasks first.

### Comprehensive Monitoring
Provides detailed real-time output including:
- Current target level based on median fluid amount
- Per-fluid pumping statistics (duration, amount added, fill percentage)
- Percentage gains relative to both previous amount and target
- Flow rates in ML/s

<img width="1971" height="1253" alt="Screenshot 2026-02-17 123028" src="https://github.com/user-attachments/assets/13f36387-291a-4b18-892a-2ee0220455db" />


## Configuration

Only modify the `priority` values in the master table. Higher numbers indicate higher priority (0-3 scale).

Key parameters:
- `dynamicTargetOffset`: Amount added to median fluid level (default: 10e9)
- `maxBatchSize`: Maximum pump run duration per iteration (default: 60s)
- `singularityCellSize`: Storage capacity per cell (4.61e18)

## Operation

The script runs in a continuous loop:
1. Queries ME network for current fluid levels
2. Calculates dynamic target based on median fluid amount
3. Identifies fluids below target and sorts by priority/fill ratio
4. Assigns available pumps to lowest fluids
5. Monitors pump execution until completion
6. Sleeps for 3 minutes if all fluids are at target

Stop execution at any time with CTRL+ALT+C.

---

## Changes from Original Version

This amended version represents a significant architectural shift from Fox's original implementation. The following changes fundamentally alter how the script manages fluid levels:

### Removed Individual Fluid Targets
The original used static per-fluid targets (`target=1e10` for each fluid). This version removes individual targets entirely, instead calculating a single dynamic target based on the median fluid amount across the network. This eliminates the need to manually tune 40+ target values and allows the system to automatically scale with network growth.

### Dynamic Target Calculation
Rather than pumping when fluids fall below `threshold * fluid.target` (75% of 10B in original), this version:
- Sorts all fluids by current amount
- Takes the median fluid amount
- Adds `dynamicTargetOffset` (10B) to establish the target
- Caps at 99% of maximum storage capacity

This means the target adjusts based on actual network state rather than arbitrary fixed values.

### Batch Size Calculation Changes
Original: `math.ceil((fluid.target - fluid.amount) / (fluid.rate * pump.mult))`  
Amended: `math.min(maxBatchSize, math.ceil((maxStorageAmount - fluid.amount) / (fluid.rate * pump.mult)))`

The amended version targets maximum storage capacity rather than individual fluid targets, preventing overfilling while maximizing throughput.

### Enhanced Output Format
The original provided simple text output. This version implements formatted tables showing:
- The median fluid used for target calculation
- Detailed before/after amounts with deltas
- Multiple percentage calculations (target gain, fill ratio, raw percentage gain)
- Real-time flow rate calculations

### Pump Assignment Algorithm
The original used a simple counter (`c = 1`) to iterate through low fluids sequentially. This version removes fluids from the queue once they reach target mid-iteration, allowing pumps to dynamically shift to the next-lowest fluid within the same cycle. This prevents pump assignment to fluids that have already been sufficiently filled by earlier pumps.

### Sorting Behavior
Both versions sort by priority first, but the amended version continuously re-sorts after each pump assignment based on updated fluid amounts. This ensures optimal pump allocation as fluid levels change during the iteration.

### Rationale
The primary motivation was eliminating manual target management as the network scales. With 40 fluids and varying consumption rates, static targets required constant adjustment. The dynamic median-based approach makes the system self-tuning while preventing the pathological case where all fluids sit at 10B (the old target) while storage capacity goes unused. Priority levels still allow critical fluids to be favored, but within a framework that adapts to actual network conditions.
