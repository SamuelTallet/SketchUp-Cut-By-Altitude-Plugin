# Cut By Altitude extension for SketchUp 2017 or newer.
# Copyright: © 2019 Samuel Tallet <samuel.tallet arobase gmail.com>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3.0 of the License, or
# (at your option) any later version.
# 
# If you release a modified version of this program TO THE PUBLIC,
# the GPL requires you to MAKE THE MODIFIED SOURCE CODE AVAILABLE
# to the program's users, UNDER THE GPL.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
# 
# Get a copy of the GPL here: https://www.gnu.org/licenses/gpl.html

raise 'The CBA plugin requires at least Ruby 2.2.0 or SketchUp 2017.'\
  unless RUBY_VERSION.to_f >= 2.2 # SketchUp 2017 includes Ruby 2.2.4.

require 'sketchup'
require 'objspace'

# CBA plugin namespace.
module CBA

  # Cutter.
  class Cut

    attr_reader :intersect_edges

    # Cuts by altitude a group, possibly many times.
    #
    # @param [Sketchup::Group] entity Entity to cut.
    # @raise [ArgumentError]
    #
    # @return [nil]
    def self.do_many_times(entity)

      raise ArgumentError, 'Entity argument must be a Sketchup::Group.'\
        unless entity.is_a?(Sketchup::Group)

      parameters = UI.inputbox(

        [
          TRANSLATE['Altitude in meters'] + ' ',
          TRANSLATE['Number of cuts'],
          TRANSLATE['Cutting direction'],
          TRANSLATE['Hide cut lines?'],
          TRANSLATE['Cut whole group?']
        ], # Prompts

        [
          1.0,
          1,
          TRANSLATE['Middle to top'],
          TRANSLATE['No'],
          TRANSLATE['No']
        ], # Defaults

        [
          '', '',
          TRANSLATE['Base to top'] + '|' +
          TRANSLATE['Top to base'] + '|' +
          TRANSLATE['Middle to base'] + '|' +
          TRANSLATE['Middle to top'],
          TRANSLATE['Yes'] +'|'+ TRANSLATE['No'],
          TRANSLATE['Yes'] +'|'+ TRANSLATE['No']
        ], # List

        TRANSLATE[NAME] # Title

      )

      # Escapes if user cancelled operation.
      return if parameters == false

      begin

        model = Sketchup.active_model

        model.start_operation(
          TRANSLATE[NAME],
          true # disable_ui
        )

        Sketchup.status_text\
          = TRANSLATE['Cut By Altitude is running... Please wait.']

        altitude = parameters[0].to_f
        base_altitude = altitude

        cut_count = parameters[1].to_i

        cut_direction = parameters[2]

        hide_cut_lines = (parameters[3] == TRANSLATE['Yes'])

        cut_whole_group = (parameters[4] == TRANSLATE['Yes'])

        entity_bounds = entity.bounds
        entity_height\
          = (entity_bounds.max.z - entity_bounds.min.z).to_l.to_m.to_f

        if cut_whole_group

          cut_count = entity_height / base_altitude
          cut_count = cut_count.to_i

        else

          if cut_direction == TRANSLATE['Top to base']

            altitude = entity_height - base_altitude

          elsif cut_direction == TRANSLATE['Middle to base']\
            || cut_direction == TRANSLATE['Middle to top']

            altitude = entity_height / 2.0

          end

        end

        temp_intersect_edges = []
        
        cut_count.times do

          cut = self.new(entity, altitude)

          temp_intersect_edges.concat(cut.intersect_edges)

          if cut_direction == TRANSLATE['Top to base']\
            || cut_direction == TRANSLATE['Middle to base']

            altitude = altitude - base_altitude

          else

            altitude = altitude + base_altitude

          end

        end

        # FIXME: Why some edges are deleted?
        intersect_edges = temp_intersect_edges.find_all { |edge|

          edge.deleted? == false

        }

        cut_lines_group = model.active_entities.add_group(
          intersect_edges
        )

        cut_lines_group.transform!(entity.transformation)

        cut_lines_group.name = 'Cut lines'

        if hide_cut_lines

          intersect_edges.each { |edge|

            edge.hidden = true

          }

          cut_lines_group.hidden = true

        end

        model.commit_operation

        Sketchup.status_text = nil
        
      rescue StandardError => exception

        model.abort_operation

        Sketchup.status_text = nil

        puts 'Error: ' + exception.message
        puts exception.backtrace
        
      end

    end

    # Initializes cut by altitude...
    #
    # @param [Sketchup::Group] entity Entity to cut.
    # @param [Numeric] altitude Altitude in meters.
    # @raise [ArgumentError]
    def initialize(entity, altitude)

      raise ArgumentError, 'Entity argument must be a Sketchup::Group.'\
        unless entity.is_a?(Sketchup::Group)

      raise ArgumentError, 'Altitude argument must be a Numeric.'\
        unless altitude.is_a?(Numeric)

      temp_edges_before_intersect = []

      entity.entities.grep(Sketchup::Edge).each { |edge|

        temp_edges_before_intersect.push(edge.object_id)

      }

      entities = Sketchup.active_model.active_entities

      entity_bounds = entity.bounds

      face = entities.add_face(
        entity_bounds.corner(0),
        entity_bounds.corner(2),
        entity_bounds.corner(3),
        entity_bounds.corner(1)
      )

      face.reverse!

      face.pushpull(
        altitude.m,
        false # copy
      )

      group = entities.add_group(face.all_connected)

      entities.intersect_with(
        true, # recurse
        Geom::Transformation.new,
        entity,
        entity.transformation,
        true, # hidden
        group
      )

      group.erase!

      temp_edges_after_intersect = []

      entity.entities.grep(Sketchup::Edge).each { |edge|

        temp_edges_after_intersect.push(edge.object_id)

      }

      temp_intersect_edges_object_ids\
        = temp_edges_after_intersect - temp_edges_before_intersect

      temp_intersect_edges = []

      temp_intersect_edges_object_ids.each { |object_id|

        temp_intersect_edges.push(ObjectSpace._id2ref(object_id))

      }

      temp_edge_altitudes = []

      temp_intersect_edges.each { |edge|

        edge_altitude = edge.vertices.last.position.z.to_i

        next if edge_altitude == 0

        temp_edge_altitudes.push(edge_altitude)

      }

      temp_edge_real_altitude = temp_edge_altitudes.uniq.min

      @intersect_edges = []

      temp_intersect_edges.each { |edge|

        edge_altitude = edge.vertices.last.position.z.to_i

        if edge_altitude == temp_edge_real_altitude

          @intersect_edges.push(edge)

        end

      }

    end

  end

end
