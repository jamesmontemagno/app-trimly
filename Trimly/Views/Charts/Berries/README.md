# Chart Berries

This directory contains 10 unique chart visualization components (called "berries") that display weight data in different ways. Each berry is a self-contained SwiftUI view that can be easily compared side-by-side.

## Overview

All berries are displayed on the Charts tab in a scrollable grid layout, allowing users to compare different visualization styles and choose their favorite.

## The 10 Berry Charts

### 1. MinimalistLineBerry
**Style:** Clean, minimalist single line chart
- Simple blue line with smooth curves
- Hidden axes for clean look
- Uses Catmull-Rom interpolation for smooth curves

### 2. AreaGradientBerry
**Style:** Filled gradient area chart
- Purple to blue gradient fill
- Area extends from minimum weight to data points
- Combines area mark with top line for clarity

### 3. BarChartBerry
**Style:** Daily bar chart
- Vertical bars for each data point
- Green to teal gradient
- Good for comparing individual days

### 4. CandlestickBerry
**Style:** Candlestick-style range display
- Shows simulated daily weight range
- Orange gradient bars with white center points
- Useful for understanding weight fluctuation

### 5. DualAxisBerry
**Style:** Dual visualization with trend line
- Blue line for actual weight
- Orange dashed line for 3-day moving average
- Shows both data and trend simultaneously

### 6. HeatmapCalendarBerry
**Style:** Calendar heatmap grid
- 4-week grid layout (7 columns)
- Color intensity shows relative weight
- Checkmarks indicate days with data
- Great for consistency tracking

### 7. MountainRidgeBerry
**Style:** Layered mountain visualization
- Multiple stacked area layers in indigo/blue
- Creates a "mountain ridge" effect
- White line traces the peak
- Dramatic and visually striking

### 8. DotMatrixBerry
**Style:** Scatter plot with color coding
- Large dots for each data point
- Color indicates weight level (green=low, yellow=medium, red=high)
- Good for spotting patterns

### 9. StepChartBerry
**Style:** Step chart with plateaus
- Cyan stepped line showing weight plateaus
- White dots mark actual measurements
- Emphasizes stable periods

### 10. BubbleChartBerry
**Style:** Bubble chart with variable sizing
- Pink to purple gradient bubbles
- Bubble size varies across timeline
- Light gray connecting line
- Unique and eye-catching

## Architecture

### Common Properties
Each berry component accepts:
- `data: [ChartDataPoint]` - Array of weight measurements
- `unit: WeightUnit` - User's preferred weight unit (kg/lb)

### Integration
All berries are displayed in `ChartsView.swift` using the `berryChartsGrid()` function, which creates a 5-row grid with 2 charts per row.

## Usage

The berries are automatically shown when viewing the Charts tab with available weight data. The range picker (Week/Month/Quarter/Year) filters the data shown in all berry charts simultaneously.

## Design Principles

1. **Self-contained:** Each berry is independent and can work without others
2. **Consistent size:** All charts use ~200px height for fair comparison
3. **Material background:** Unified `.ultraThinMaterial` background
4. **Responsive:** Adapts to user's weight unit preference
5. **Accessible:** Clear labels and visual hierarchy

## Future Enhancements

Potential improvements could include:
- User ability to select and pin their favorite berry
- Custom color themes for each berry
- Interactive tooltips on tap
- Export individual chart images
- Additional berry variations
