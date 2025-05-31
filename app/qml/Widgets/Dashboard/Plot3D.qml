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
import QtQuick.Layouts
import QtQuick.Controls

import QtQuick3D

import SerialStudio

import "../"

Item {
  id: root

  //
  // Widget data inputs
  //
  required property color color
  required property Plot3DModel model
  required property MiniWindow windowRoot

  //
  // Window flags
  //
  readonly property bool hasToolbar: root.width >= toolbar.implicitWidth

  //
  // Update plot geometry automatically
  //
  onModelChanged: {
    root.model.geometry = customGeometry
  }

  //
  // Zoom in/out shortcuts
  //
  Shortcut {
    enabled: windowRoot.focused
    sequences: [StandardKey.ZoomIn]
    onActivated: {
      if (view.cameraDistance > 10)
        view.cameraDistance -= 50
    }
  } Shortcut {
    enabled: windowRoot.focused
    sequences: [StandardKey.ZoomOut]
    onActivated: {
      view.cameraDistance += 50
    }
  }

  //
  // Add toolbar
  //
  RowLayout {
    id: toolbar

    spacing: 4
    visible: root.hasToolbar
    height: root.hasToolbar ? 48 : 0

    anchors {
      leftMargin: 8
      top: parent.top
      left: parent.left
      right: parent.right
    }

    ToolButton {
      width: 24
      height: 24
      icon.width: 18
      icon.height: 18
      icon.color: "transparent"
      checked: model.interpolationEnabled
      onClicked: model.interpolationEnabled = !model.interpolationEnabled
      icon.source: model.interpolationEnabled ?
                     "qrc:/rcc/icons/dashboard-buttons/interpolate-on.svg" :
                     "qrc:/rcc/icons/dashboard-buttons/interpolate-off.svg"
    }

    ToolButton {
      width: 24
      height: 24
      icon.width: 18
      icon.height: 18
      checked: view.showAxes
      icon.color: "transparent"
      onClicked: view.showAxes = !view.showAxes
      icon.source: "qrc:/rcc/icons/dashboard-buttons/abscissa.svg"
    }

    Rectangle {
      implicitWidth: 1
      implicitHeight: 24
      color: Cpp_ThemeManager.colors["widget_border"]
    }

    ToolButton {
      width: 24
      height: 24
      icon.width: 18
      icon.height: 18
      icon.color: "transparent"
      checked: view.orbbitNavigation
      onClicked: view.orbbitNavigation = true
      icon.source: "qrc:/rcc/icons/dashboard-buttons/orbit.svg"
    }

    ToolButton {
      width: 24
      height: 24
      icon.width: 18
      icon.height: 18
      icon.color: "transparent"
      checked: !view.orbbitNavigation
      onClicked: view.orbbitNavigation = false
      icon.source: "qrc:/rcc/icons/dashboard-buttons/pan.svg"
    }

    Rectangle {
      implicitWidth: 1
      implicitHeight: 24
      color: Cpp_ThemeManager.colors["widget_border"]
    }

    ToolButton {
      width: 24
      height: 24
      icon.width: 18
      icon.height: 18
      icon.color: "transparent"
      onClicked: view.animateToView(225, 60)
      icon.source: "qrc:/rcc/icons/dashboard-buttons/orthogonal_view.svg"
    }

    ToolButton {
      width: 24
      height: 24
      icon.width: 18
      icon.height: 18
      icon.color: "transparent"
      onClicked: view.animateToView(0, 0)
      icon.source: "qrc:/rcc/icons/dashboard-buttons/top_view.svg"
    }

    ToolButton {
      width: 24
      height: 24
      icon.width: 18
      icon.height: 18
      icon.color: "transparent"
      onClicked: view.animateToView(270, 80)
      icon.source: "qrc:/rcc/icons/dashboard-buttons/left_view.svg"
    }

    ToolButton {
      width: 24
      height: 24
      icon.width: 18
      icon.height: 18
      icon.color: "transparent"
      onClicked: view.animateToView(180, 80)
      icon.source: "qrc:/rcc/icons/dashboard-buttons/front_view.svg"
    }

    Rectangle {
      implicitWidth: 1
      implicitHeight: 24
      color: Cpp_ThemeManager.colors["widget_border"]
    }

    ToolButton {
      width: 24
      height: 24
      icon.width: 18
      icon.height: 18
      icon.color: "transparent"
      checked: view.anaglyphEnabled
      onClicked: view.anaglyphEnabled = !view.anaglyphEnabled
      icon.source: "qrc:/rcc/icons/dashboard-buttons/anaglyph.svg"
    }

    Slider {
      from: 0
      to: 5000
      stepSize: 1
      Layout.fillWidth: true
      Layout.maximumWidth: 128
      enabled: view.anaglyphEnabled
      value: view.eyeSeparation * 1e3
      opacity: view.anaglyphEnabled ? 1 : 0
      onValueChanged: {
        var separation = value / 1e3
        if (view.eyeSeparation !== separation)
          view.eyeSeparation = separation
      }
    }

    Item {
      Layout.fillWidth: true
    }
  }

  //
  // 3D Plot view
  //
  Plot3DWidget {
    id: view
    anchors.fill: parent
    anchors.topMargin: root.hasToolbar ? 48 : 0
    backgroundColor: Cpp_ThemeManager.colors["widget_window"]

    geometry: Plot3DGeometry {
      id: customGeometry
      onBoundsChanged: {
        view.updateGeometryCenter()
      }
    }

    materials: DefaultMaterial {
      lineWidth: 2.0
      pointSize: 2.0
      diffuseColor: model.diffuseColor
      lighting: DefaultMaterial.NoLighting
    }
  }
}
