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

#pragma once

#include <QVector3D>
#include <QQuickItem>
#include <QQuick3DGeometry>

namespace Widgets
{
/**
 * @brief Geometry class for rendering 3D point or line strip data in QtQuick3D.
 *
 * This class wraps low-level geometry buffer updates to allow real-time
 * rendering of QVector<QVector3D> data from a dashboard or sensor input.
 */
class Plot3DGeometry : public QQuick3DGeometry
{
  Q_OBJECT
  Q_PROPERTY(QVector3D boundsMin READ boundsMin NOTIFY boundsChanged)
  Q_PROPERTY(QVector3D boundsMax READ boundsMax NOTIFY boundsChanged)

signals:
  void boundsChanged();

public:
  Plot3DGeometry(QQuick3DObject *parent = nullptr);

  [[nodiscard]] QVector3D boundsMin() const;
  [[nodiscard]] QVector3D boundsMax() const;

  void updateData(const QVector<QVector3D> &points, bool useLineStrip);

private:
  QVector3D m_min;
  QVector3D m_max;
};

/**
 * @brief 3D plotting widget for visualizing real-time QVector3D data.
 *
 * This class integrates with the UI::Dashboard backend and updates a
 * QQuick3DGeometry object based on incoming 3D point data. It supports both
 * point cloud and line strip rendering modes.
 */
class Plot3D : public QQuickItem
{
  // clang-format off
  Q_OBJECT
  Q_PROPERTY(QColor diffuseColor
             READ diffuseColor
             NOTIFY colorsChanged)
  Q_PROPERTY(Plot3DGeometry* geometry
             READ geometry
             WRITE setGeometry
             NOTIFY geometryChanged)
  Q_PROPERTY(bool interpolationEnabled
             READ interpolationEnabled
             WRITE setInterpolationEnabled
             NOTIFY interpolationEnabledChanged)
  // clang-format on

signals:
  void colorsChanged();
  void geometryChanged();
  void interpolationEnabledChanged();

public:
  explicit Plot3D(const int index = -1, QQuickItem *parent = nullptr);

  [[nodiscard]] QColor diffuseColor() const;
  ;
  [[nodiscard]] bool interpolationEnabled() const;
  [[nodiscard]] Widgets::Plot3DGeometry *geometry() const;

public slots:
  void setInterpolationEnabled(const bool enabled);
  void setGeometry(Widgets::Plot3DGeometry *geometry);

private slots:
  void updateData();
  void onThemeChanged();

private:
  int m_index;
  QColor m_diffuseColor;
  Plot3DGeometry *m_geometry;
  bool m_interpolationEnabled;
};
} // namespace Widgets
