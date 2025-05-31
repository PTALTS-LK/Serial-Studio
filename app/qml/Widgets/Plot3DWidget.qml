/*
 * Serial Studio - https://serial-studio.github.io/
 *
 * Copyright (C) 2020-2025 Alex Spataru <https://aspatru.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick3D
import Qt3D.Extras
import QtQuick3D.Helpers

Item {
  id: root
  anchors.fill: parent

  //
  // Public control flags
  //
  property real eyeSeparation: 2.47
  property bool orbbitNavigation: true
  property bool anaglyphEnabled: false

  //
  // Required input properties
  //
  required property Geometry geometry
  required property Material materials

  //
  // Internal state
  //
  property real phi: 60
  property real lastX: 0
  property real lastY: 0
  property real theta: 45
  property bool mousePressed: false
  property real cameraDistance: 600
  property vector3d cameraTarget: Qt.vector3d(0, 0, 0)
  property vector3d geometryCenter: Qt.vector3d(0, 0, 0)

  //
  // Limits
  //
  property real minCameraDistance: 1
  property real maxCameraDistance: 5000
  property real clipFar: cameraDistance * 4

  //
  // Aliases
  //
  property alias showAxes: grid.gridAxes
  property alias backgroundColor: env.clearColor

  //
  // Derived camera position from spherical coordinates
  //
  function updateCameraPosition() {
    const radTheta = theta * Math.PI / 180
    const radPhi = phi * Math.PI / 180

    const eyeX = cameraDistance * Math.sin(radPhi) * Math.cos(radTheta)
    const eyeY = cameraDistance * Math.cos(radPhi)
    const eyeZ = cameraDistance * Math.sin(radPhi) * Math.sin(radTheta)
    const viewOffset = Qt.vector3d(eyeX, eyeY, eyeZ)
    const cameraPos = cameraTarget.plus(viewOffset)

    if (!anaglyphEnabled) {
      mainCamera.position = cameraPos
      mainCamera.lookAt(cameraTarget)
    } else {
      const viewDir = cameraTarget.minus(cameraPos).normalized()
      const right = Qt.vector3d(viewDir.y, -viewDir.x, 0).normalized()

      const separationScale = cameraDistance * 0.01
      const stereoOffset = right.times(eyeSeparation * 0.5 * separationScale)

      leftCamera.position = cameraPos.minus(stereoOffset)
      rightCamera.position = cameraPos.plus(stereoOffset)

      leftCamera.lookAt(cameraTarget)
      rightCamera.lookAt(cameraTarget)
    }
  }

  //
  // Updates the center of the model
  //
  function updateGeometryCenter() {
    if (!root.geometry)
      return

    const min = root.geometry.boundsMin
    const max = root.geometry.boundsMax

    const dx = max.x - min.x
    const dy = max.y - min.y
    const dz = max.z - min.z
    const radius = 0.5 * Math.sqrt(dx*dx + dy*dy + dz*dz)
    root.maxCameraDistance = radius * 3.0

    if (root.cameraDistance > root.maxCameraDistance) {
      root.cameraDistance = root.maxCameraDistance
      updateCameraPosition()
    }

    geometryCenter = Qt.vector3d(
          0.5 * (min.x + max.x),
          0.5 * (min.y + max.y),
          0.5 * (min.z + max.z)
          )
  }

  //
  // Smoothly animates the camera to a given orbit distance and orientation
  //
  function animateToView(targetTheta, targetPhi) {
    zoomAnimation.to = maxCameraDistance
    thetaAnimation.to = targetTheta
    phiAnimation.to = targetPhi
    targetAnimation.to = Qt.vector3d(0, 0, 0)

    zoomAnimation.start()
    thetaAnimation.start()
    phiAnimation.start()
    targetAnimation.start()
  }

  //
  // Update camera position automatically
  //
  onPhiChanged: updateCameraPosition()
  onThetaChanged: updateCameraPosition()
  Component.onCompleted: updateCameraPosition()
  onEyeSeparationChanged: updateCameraPosition()
  onCameraDistanceChanged: updateCameraPosition()
  onAnaglyphEnabledChanged: updateCameraPosition()

  //
  // Animations
  //
  NumberAnimation {
    id: zoomAnimation
    target: root
    property: "cameraDistance"
    duration: 400
  } NumberAnimation {
    id: thetaAnimation
    target: root
    property: "theta"
    duration: 400
  } NumberAnimation {
    id: phiAnimation
    target: root
    property: "phi"
    duration: 400
  } Vector3dAnimation {
    id: targetAnimation
    target: root
    property: "cameraTarget"
    duration: 400
  }

  //
  // Scene environment
  //
  SceneEnvironment {
    id: env
    backgroundMode: SceneEnvironment.Color
    antialiasingMode: SceneEnvironment.MSAA
    antialiasingQuality: SceneEnvironment.High

    Node {
      eulerRotation.x: -90

      InfiniteGrid {
        id: grid
        gridInterval: {
          const levels = [1, 5, 10, 50, 100, 500, 1000]
          let best = levels[0]
          let minDiff = Math.abs(cameraDistance - levels[0])
          for (let i = 0; i < levels.length; ++i) {
            const diff = Math.abs(cameraDistance - levels[i])
            if (diff < minDiff) {
              best = levels[i]
              minDiff = diff
            }
          }
          return best
        }
      }
    }
  }

  //
  // Regular view (non-anaglyph)
  //
  View3D {
    id: monoView
    environment: env
    anchors.fill: parent
    visible: !anaglyphEnabled

    PerspectiveCamera {
      id: mainCamera
      clipNear: 0.1
      clipFar: root.clipFar
    }

    Node {
      eulerRotation.x: -90

      Model {
        geometry: root.geometry
        materials: root.materials
      }
    }
  }

  //
  // Anaglyph view
  //
  Item {
    anchors.fill: parent
    visible: anaglyphEnabled

    View3D {
      id: leftEye
      environment: env
      anchors.fill: parent


      PerspectiveCamera {
        id: leftCamera
        clipNear: 0.1
        clipFar: root.clipFar
      }

      Node {
        eulerRotation.x: -90

        Model {
          geometry: root.geometry
          materials: root.materials
        }
      }
    }

    View3D {
      id: rightEye
      environment: env
      anchors.fill: parent

      PerspectiveCamera {
        id: rightCamera
        clipNear: 0.1
        clipFar: root.clipFar
      }

      Node {
        eulerRotation.x: -90

        Model {
          geometry: root.geometry
          materials: root.materials
        }
      }
    }

    ShaderEffect {
      anchors.fill: parent
      property variant leftSource: leftEye
      property variant rightSource: rightEye
      fragmentShader: "qrc:/rcc/shaders/anaglyph.frag.qsb"
    }
  }

  //
  // Mouse interaction
  //
  MouseArea {
    anchors.fill: parent
    onReleased: mousePressed = false
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: mousePressed ? Qt.ClosedHandCursor : Qt.ArrowCursor

    onPressed: (mouse) => {
                 lastX = mouse.x
                 lastY = mouse.y
                 mousePressed = true
               }

    onPositionChanged: (mouse) => {
                         if (!mousePressed)
                         return

                         let dx = mouse.x - lastX
                         let dy = mouse.y - lastY
                         lastX = mouse.x
                         lastY = mouse.y

                         if (orbbitNavigation) {
                           theta = (theta - dx * 0.5) % 360
                           if (theta < 0)
                           theta += 360

                           phi = Math.max(5, Math.min(175, phi - dy * 0.5))
                           updateCameraPosition()
                         }

                         else {
                           const right = Qt.vector3d(
                             Math.cos(theta * Math.PI / 180),
                             0,
                             -Math.sin(theta * Math.PI / 180)
                             )
                           const up = Qt.vector3d(0, 1, 0)

                           const panScale = cameraDistance * 0.0025
                           cameraTarget = cameraTarget
                           .minus(right.times(dx * panScale))
                           .plus(up.times(dy * panScale))
                           updateCameraPosition()
                         }
                       }

    onWheel: (wheel) => {
               cameraDistance *= (wheel.angleDelta.y > 0) ? 0.9 : 1.1
               cameraDistance = Math.max(minCameraDistance, Math.min(cameraDistance, maxCameraDistance))
               updateCameraPosition()
             }
  }
}
