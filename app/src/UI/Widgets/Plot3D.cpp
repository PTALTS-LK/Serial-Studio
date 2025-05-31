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

#include "UI/Dashboard.h"
#include "UI/Widgets/Plot3D.h"
#include "Misc/ThemeManager.h"

//------------------------------------------------------------------------------
// Plot3D geometry class implementation
//------------------------------------------------------------------------------

/**
 * @brief Constructs a Plot3DGeometry object.
 * @param parent The parent QQuick3DObject (typically a Model).
 */
Widgets::Plot3DGeometry::Plot3DGeometry(QQuick3DObject *parent)
  : QQuick3DGeometry(parent)
{
  setStride(3 * sizeof(float));
  addAttribute(Attribute::PositionSemantic, 0, Attribute::F32Type);
}

QVector3D Widgets::Plot3DGeometry::boundsMin() const
{
  return m_min;
}

QVector3D Widgets::Plot3DGeometry::boundsMax() const
{
  return m_max;
}

/**
 * @brief Updates the vertex and index buffers with new 3D data.
 * Replaces all existing vertex/index data and updates the bounding box.
 *
 * @param points      A vector of 3D points to plot.
 * @param interpolate If true, data is rendered as a continuous line strip;
 *                    otherwise, individual points are rendered.
 */
void Widgets::Plot3DGeometry::updateData(const QVector<QVector3D> &points,
                                         bool interpolate)
{
  // Skip update if no data is provided
  if (points.isEmpty())
    return;

  // Obtain drawing type
  auto type = interpolate ? PrimitiveType::LineStrip : PrimitiveType::Points;

  // Allocate vertex buffer and compute bounds (min/max)
  QVector3D min = points.first();
  QVector3D max = points.first();
  QByteArray vertexBuffer(points.size() * 3 * sizeof(float), Qt::Uninitialized);
  float *v = reinterpret_cast<float *>(vertexBuffer.data());
  for (const QVector3D &p : points)
  {
    *v++ = p.x();
    *v++ = p.y();
    *v++ = p.z();

    min.setX(qMin(min.x(), p.x()));
    min.setY(qMin(min.y(), p.y()));
    min.setZ(qMin(min.z(), p.z()));
    max.setX(qMax(max.x(), p.x()));
    max.setY(qMax(max.y(), p.y()));
    max.setZ(qMax(max.z(), p.z()));
  }

  // Build index buffer with sequential indices
  QByteArray indexBuffer(points.size() * sizeof(quint32), Qt::Uninitialized);
  quint32 *i = reinterpret_cast<quint32 *>(indexBuffer.data());
  for (quint32 j = 0; j < static_cast<quint32>(points.size()); ++j)
    *i++ = j;

  // Reset geometry state before applying new data
  clear();

  // Apply geometry configuration
  setBounds(min, max);
  setVertexData(vertexBuffer);
  setStride(3 * sizeof(float));
  setIndexData(0, indexBuffer);
  setPrimitiveType(type);
  addAttribute(Attribute::PositionSemantic, 0, Attribute::F32Type);

  // Update bounds
  if (m_min != min || m_max != max)
  {
    m_min = min;
    m_max = max;
    Q_EMIT boundsChanged();
  }

  // Request scenegraph update
  update();
}

//------------------------------------------------------------------------------
// Plot3D model class implementation
//------------------------------------------------------------------------------

/**
 * @brief Constructs the widget and connects it to the dashboard update signal.
 * @param index The dashboard plot index to track.
 * @param parent The parent QQuickItem.
 */
Widgets::Plot3D::Plot3D(const int index, QQuickItem *parent)
  : QQuickItem(parent)
  , m_index(index)
  , m_geometry(nullptr)
  , m_interpolationEnabled(true)
{
  // Obtain real time data from the dashboard
  connect(&UI::Dashboard::instance(), &UI::Dashboard::updated, this,
          &Widgets::Plot3D::updateData);

  // Connect to the theme manager to update the curve colors
  onThemeChanged();
  connect(&Misc::ThemeManager::instance(), &Misc::ThemeManager::themeChanged,
          this, &Widgets::Plot3D::onThemeChanged);
}

/**
 * @brief Returns the geometry object used for rendering the 3D plot.
 * @return Pointer to the Plot3DGeometry object.
 */
Widgets::Plot3DGeometry *Widgets::Plot3D::geometry() const
{
  return m_geometry;
}

/**
 * @brief Returns the diffuse color used by the plot's material.
 *
 * This color defines the primary visible color of the geometry surface
 * when lighting is enabled. It is typically used to distinguish the plot
 * visually in the scene.
 *
 * @return The currently configured diffuse color.
 */
QColor Widgets::Plot3D::diffuseColor() const
{
  return m_diffuseColor;
}

/**
 * @brief Returns whether line strip interpolation is currently enabled.
 * @return True if interpolation is enabled; false for point mode.
 */
bool Widgets::Plot3D::interpolationEnabled() const
{
  return m_interpolationEnabled;
}

/**
 * @brief Enables or disables line strip interpolation mode.
 * @param enabled If true, data will be rendered as a connected line strip.
 */
void Widgets::Plot3D::setInterpolationEnabled(const bool enabled)
{
  if (m_interpolationEnabled != enabled)
  {
    m_interpolationEnabled = enabled;
    updateData();

    Q_EMIT interpolationEnabledChanged();
  }
}

/**
 * @brief Sets the geometry object used by this plot.
 * @param geometry Pointer to the Plot3DGeometry to associate with this plot.
 */
void Widgets::Plot3D::setGeometry(Widgets::Plot3DGeometry *geometry)
{
  if (geometry && m_geometry != geometry)
  {
    m_geometry = geometry;
    Q_EMIT geometryChanged();
  }
}

/**
 * @brief Updates the geometry with new 3D point data from the dashboard.
 *
 * This method validates the widget's index and, if valid and data is available,
 * forwards the data to the associated Plot3DGeometry instance.
 */
void Widgets::Plot3D::updateData()
{
  // Validate that the widget exists
  if (!VALIDATE_WIDGET(SerialStudio::DashboardPlot3D, m_index))
    return;

  // Obtain data from dashboard
  const auto &data = UI::Dashboard::instance().plotData3D(m_index);
  if (data.isEmpty())
    return;

  // Update geometry
  if (m_geometry)
    m_geometry->updateData(data, m_interpolationEnabled);
}

/**
 * @brief Updates plot colors based on the current theme.
 */
void Widgets::Plot3D::onThemeChanged()
{
  // Obtain color for widget index
  auto c = Misc::ThemeManager::instance().colors()["widget_colors"].toArray();
  if (c.count() > m_index)
    m_diffuseColor = c.at(m_index).toString();
  else
    m_diffuseColor = c.at(m_index % c.count()).toString();

  // Redraw the plot
  Q_EMIT colorsChanged();
}
