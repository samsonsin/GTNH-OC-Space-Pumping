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
Fluids are assigned priority levels, with higher priority fluids pumped first when multiple fluids fall below target. Within the same priority tier, the script favors fluids with the lowest fill ratio, ensuring the most depleted resources receive attention.

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
- Flow rates
- SI prefix shortening

<img width="1971" height="1253" alt="Screenshot 2026-02-17 123028" src="https://github.com/user-attachments/assets/13f36387-291a-4b18-892a-2ee0220455db" />


## Configuration

Only modify the `priority` values in the master table. Higher numbers indicate higher priority. as long as your mean has the lowest priority (so, at least 21 fluids are of the lowest priority) all fluids will be stocked. otherwise the offset will "run away" and not stock low priority fluids. If you want this feature, make a issue or something and I'll fix it.

Key parameters:
- `dynamicTargetOffset`: Amount added to median fluid level (default: 10e9). In practice will determine how big the difference between the mean and the max will be, higher numbers mean a larger amount of high priority fluid will be grabbed before low priority fluids.
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