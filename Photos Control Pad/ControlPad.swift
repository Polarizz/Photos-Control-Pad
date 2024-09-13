//
//  ControlPad.swift
//  Photos Control Pad
//
//  Created by Paul Wong on 9/13/24.
//

import SwiftUI

/// A SwiftUI view representing a control pad with a movable circle over a grid of dots.
/// The circle's position updates `xValue` and `yValue`, which can be bound to external states.
struct ControlPad: View {

    // MARK: - Properties

    /// State variable to track the circle's position.
    @State private var circlePosition: CGPoint?

    /// Circle's radius; changes when being dragged.
    @State private var circleRadius: CGFloat = 5

    /// Binding variables to pass the x and y values to the parent view.
    @Binding var xValue: CGFloat
    @Binding var yValue: CGFloat

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            // Constants for grid and layout.
            let gridSize = 11
            let padding: CGFloat = 10
            let totalSize = min(geometry.size.width, geometry.size.height)
            let dotCellSize = (totalSize - 2 * padding) / CGFloat(gridSize)

            // Calculate movable area bounds based on the current circle radius.
            let bounds = movableBounds(totalSize: totalSize, padding: padding, circleRadius: circleRadius)

            // Initialize circle position if not already set.
            let initialPosition = CGPoint(x: (bounds.minX + bounds.maxX) / 2,
                                          y: (bounds.minY + bounds.maxY) / 2)
            let circlePosition = self.circlePosition ?? initialPosition

            ZStack {
                // Background with gesture attached.
                ZStack {
                    Color.gray
                }
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.2), lineWidth: 3)
                )
                .frame(width: totalSize, height: totalSize)
                .gesture(
                    // Drag gesture to move the circle.
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            var newLocation = value.location

                            // Increase circle radius when touch down.
                            withAnimation(.easeInOut(duration: 0.39)) {
                                self.circleRadius = 16
                            }

                            // Recalculate movable area bounds based on the new circle radius.
                            let bounds = movableBounds(totalSize: totalSize, padding: padding, circleRadius: circleRadius)

                            // Constrain the circle's position within the bounds.
                            newLocation = constrainPoint(newLocation, within: bounds)

                            // Snap circle to the nearest grid dot if within threshold.
                            newLocation = snapToGrid(position: newLocation,
                                                     padding: padding,
                                                     dotCellSize: dotCellSize,
                                                     gridSize: gridSize,
                                                     snapThreshold: dotCellSize * 0.4)

                            self.circlePosition = newLocation

                            // Update xValue and yValue based on the new position.
                            updateValues(newLocation: newLocation, bounds: bounds)
                        }
                        .onEnded { _ in
                            // Snap to nearest grid dot on touch up.
                            if let currentPosition = self.circlePosition {
                                let snappedPosition = snapToGrid(position: currentPosition,
                                                                 padding: padding,
                                                                 dotCellSize: dotCellSize,
                                                                 gridSize: gridSize,
                                                                 snapThreshold: .infinity)

                                withAnimation(.easeInOut(duration: 0.39)) {
                                    // Snap circle to grid dot and reset radius.
                                    self.circlePosition = snappedPosition
                                    self.circleRadius = 5
                                }
                            } else {
                                // Reset circle radius on touch up.
                                withAnimation(.easeInOut(duration: 0.39)) {
                                    self.circleRadius = 5
                                }
                            }
                        }
                )

                // Grid of dots and movable circle.
                ZStack {
                    // Grid of dots.
                    drawGrid(circlePosition: circlePosition,
                             gridSize: gridSize,
                             dotCellSize: dotCellSize,
                             padding: padding,
                             circleRadius: circleRadius)

                    // Movable circle.
                    Circle()
                        .fill(Color.white)
                        .frame(width: circleRadius * 2, height: circleRadius * 2)
                        .blur(radius: circleRadius == 16 ? 3 : 0)
                        .brightness(circleRadius == 16 ? 0.3 : 0)
                        .position(circlePosition)
                        .animation(.easeInOut(duration: 0.39), value: circleRadius)
                }
            }
            .frame(width: totalSize, height: totalSize)
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 3)
            .shadow(color: Color.black.opacity(0.16), radius: 39, x: 0, y: 16)
            .animation(.easeInOut(duration: 0.39), value: circlePosition)
        }
        .frame(width: 139, height: 139)
    }

    // MARK: - Helper Functions

    /// Calculates the movable area bounds based on the circle radius.
    private func movableBounds(totalSize: CGFloat, padding: CGFloat, circleRadius: CGFloat) -> (minX: CGFloat, maxX: CGFloat, minY: CGFloat, maxY: CGFloat) {
        let minX = padding + circleRadius
        let maxX = totalSize - padding - circleRadius
        let minY = padding + circleRadius
        let maxY = totalSize - padding - circleRadius
        return (minX, maxX, minY, maxY)
    }

    /// Constrains a point within the specified bounds.
    private func constrainPoint(_ point: CGPoint, within bounds: (minX: CGFloat, maxX: CGFloat, minY: CGFloat, maxY: CGFloat)) -> CGPoint {
        var constrainedPoint = point
        constrainedPoint.x = min(max(point.x, bounds.minX), bounds.maxX)
        constrainedPoint.y = min(max(point.y, bounds.minY), bounds.maxY)
        return constrainedPoint
    }

    /// Snaps the given position to the nearest grid dot if within the snap threshold.
    private func snapToGrid(position: CGPoint, padding: CGFloat, dotCellSize: CGFloat, gridSize: Int, snapThreshold: CGFloat) -> CGPoint {
        let column = Int(round((position.x - padding - dotCellSize / 2) / dotCellSize))
        let row = Int(round((position.y - padding - dotCellSize / 2) / dotCellSize))
        let clampedColumn = min(max(column, 0), gridSize - 1)
        let clampedRow = min(max(row, 0), gridSize - 1)

        let gridDotCenterX = padding + (CGFloat(clampedColumn) + 0.5) * dotCellSize
        let gridDotCenterY = padding + (CGFloat(clampedRow) + 0.5) * dotCellSize

        let dx = gridDotCenterX - position.x
        let dy = gridDotCenterY - position.y
        let distance = sqrt(dx * dx + dy * dy)

        // If within snap threshold, snap to grid dot.
        if distance < snapThreshold {
            return CGPoint(x: gridDotCenterX, y: gridDotCenterY)
        } else {
            return position
        }
    }

    /// Updates `xValue` and `yValue` based on the new circle position.
    private func updateValues(newLocation: CGPoint, bounds: (minX: CGFloat, maxX: CGFloat, minY: CGFloat, maxY: CGFloat)) {
        let centerX = (bounds.minX + bounds.maxX) / 2
        let centerY = (bounds.minY + bounds.maxY) / 2

        // xValue ranges from -100 to 100.
        self.xValue = ((newLocation.x - centerX) / (bounds.maxX - centerX)) * 100
        // yValue ranges from -100 to 100.
        self.yValue = ((centerY - newLocation.y) / (centerY - bounds.minY)) * 100
    }

    /// Draws the grid of dots.
    private func drawGrid(circlePosition: CGPoint,
                          gridSize: Int,
                          dotCellSize: CGFloat,
                          padding: CGFloat,
                          circleRadius: CGFloat) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.fixed(dotCellSize), spacing: 0), count: gridSize),
            spacing: 0
        ) {
            ForEach(0..<gridSize * gridSize, id: \.self) { index in
                let row = index / gridSize
                let column = index % gridSize

                // Calculate the dot's center position.
                let dotX = padding + (CGFloat(column) + 0.5) * dotCellSize
                let dotY = padding + (CGFloat(row) + 0.5) * dotCellSize

                // Calculate the distance from the dot to the circle's center.
                let dx = dotX - circlePosition.x
                let dy = dotY - circlePosition.y
                let distance = sqrt(dx * dx + dy * dy)

                // Define a maximum distance for full effect.
                let maxDistance: CGFloat = dotCellSize * 4.5

                // Calculate normalized distance.
                let normalizedDistance = min(distance / maxDistance, 1.0)

                // Calculate base opacity based on distance.
                let baseOpacity = max(0.3, 1.0 - normalizedDistance)

                // Check if the dot is aligned with the circle's center.
                let isAlignedX = abs(dotX - circlePosition.x) < dotCellSize / 2
                let isAlignedY = abs(dotY - circlePosition.y) < dotCellSize / 2

                // Increase opacity for dots along the axes.
                let opacity = (isAlignedX || isAlignedY) ? max(baseOpacity, 0.7) : baseOpacity

                // Calculate dot size based on distance.
                let minDotSize: CGFloat = 3
                let maxDotSize: CGFloat = circleRadius == 16 ? 9 : 5
                let dotSize = minDotSize + (maxDotSize - minDotSize) * (1.0 - normalizedDistance)

                if row == gridSize / 2 && column == gridSize / 2 {
                    // This is the center dot.
                    Circle()
                        .strokeBorder(Color.white.opacity(opacity), lineWidth: 1)
                        .frame(width: 5, height: 5)
                        .frame(width: dotCellSize, height: dotCellSize)
                } else {
                    // Other dots.
                    Circle()
                        .fill(Color.white.opacity(opacity))
                        .frame(width: dotSize, height: dotSize)
                        .frame(width: dotCellSize, height: dotCellSize)
                }
            }
        }
        .padding(padding)
    }
}
